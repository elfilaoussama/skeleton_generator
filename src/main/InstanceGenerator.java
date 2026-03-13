package main;

import edu.mit.csail.sdg.alloy4.A4Reporter;
import edu.mit.csail.sdg.alloy4compiler.ast.Command;
import edu.mit.csail.sdg.alloy4compiler.ast.Module;
import edu.mit.csail.sdg.alloy4compiler.parser.CompUtil;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Options;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Solution;
import edu.mit.csail.sdg.alloy4compiler.translator.TranslateAlloyToKodkod;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.Random;

public class InstanceGenerator {

    static int[] parseBound(String val) {
        if (val.contains("-")) {
            String[] parts = val.split("-");
            return new int[]{Integer.parseInt(parts[0]), Integer.parseInt(parts[1])};
        } else {
            int v = Integer.parseInt(val);
            return new int[]{v, v};
        }
    }

    public static void main(String[] args) throws Exception {
        System.out.println("Starting Skeleton Generator Pipeline (Parallel Mode)...");
        
        String baseAlsFile = "models/final_class_hierarchies.als";
        int targetInstances = 3;
        int[] classesBound = {5, 5};
        int[] methodsBound = {6, 6};
        int[] attributesBound = {4, 4};
        int minDepth = 1;
        int maxCoupling = -1;
        int bitwidth = 5;
        String format = "xml";
        int threads = Runtime.getRuntime().availableProcessors();
        
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals("--classes") && i + 1 < args.length) classesBound = parseBound(args[++i]);
            if (args[i].equals("--methods") && i + 1 < args.length) methodsBound = parseBound(args[++i]);
            if (args[i].equals("--attributes") && i + 1 < args.length) attributesBound = parseBound(args[++i]);
            if (args[i].equals("--min-depth") && i + 1 < args.length) minDepth = Integer.parseInt(args[++i]);
            if (args[i].equals("--max-coupling") && i + 1 < args.length) maxCoupling = Integer.parseInt(args[++i]);
            if (args[i].equals("--bitwidth") && i + 1 < args.length) bitwidth = Integer.parseInt(args[++i]);
            if (args[i].equals("--instances") && i + 1 < args.length) targetInstances = Integer.parseInt(args[++i]);
            if (args[i].equals("--model") && i + 1 < args.length) baseAlsFile = args[++i];
            if (args[i].equals("--format") && i + 1 < args.length) format = args[++i].toLowerCase();
            if (args[i].equals("--threads") && i + 1 < args.length) threads = Integer.parseInt(args[++i]);
        }
        
        String baseContent = new String(Files.readAllBytes(Paths.get(baseAlsFile)));
        
        System.out.println("Configured parameters: Classes in [" + classesBound[0] + "-" + classesBound[1] + "], " +
                           "Methods in [" + methodsBound[0] + "-" + methodsBound[1] + "], " + 
                           "Attributes in [" + attributesBound[0] + "-" + attributesBound[1] + "], " +
                           "Sol requested=" + targetInstances + ", Format=" + format + ", Threads=" + threads);
        
        ConcurrentHashMap<String, Integer> combinationCounts = new ConcurrentHashMap<>();
        AtomicInteger generated = new AtomicInteger(0);
        AtomicInteger attempts = new AtomicInteger(0);
        int maxAttempts = targetInstances * 10;
        
        File outDir = new File("output");
        if (!outDir.exists()) outDir.mkdirs();
        
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        
        // Capture effective variables for lambda
        final int[] fClassesBound = classesBound;
        final int[] fMethodsBound = methodsBound;
        final int[] fAttributesBound = attributesBound;
        final int fMinDepth = minDepth;
        final int fMaxCoupling = maxCoupling;
        final int fBitwidth = bitwidth;
        final int fTargetInstances = targetInstances;
        final String fFormat = format;
        final String fBaseContent = baseContent;
        
        for (int i = 0; i < maxAttempts; i++) {
            executor.submit(() -> {
                if (generated.get() >= fTargetInstances) return;
                
                int currentAttempt = attempts.incrementAndGet();
                if (currentAttempt > maxAttempts) return;
                
                Random rand = new Random();
                int c = fClassesBound[0] + (fClassesBound[1] > fClassesBound[0] ? rand.nextInt(fClassesBound[1] - fClassesBound[0] + 1) : 0);
                int m = fMethodsBound[0] + (fMethodsBound[1] > fMethodsBound[0] ? rand.nextInt(fMethodsBound[1] - fMethodsBound[0] + 1) : 0);
                int a = fAttributesBound[0] + (fAttributesBound[1] > fAttributesBound[0] ? rand.nextInt(fAttributesBound[1] - fAttributesBound[0] + 1) : 0);
                
                String comboKey = c + "-" + m + "-" + a;
                int priorSolutions;
                
                // Synchronize block ensures exact offsets are strictly reserved across parallel threads avoiding duplicate files
                synchronized (combinationCounts) {
                    priorSolutions = combinationCounts.getOrDefault(comboKey, 0);
                    combinationCounts.put(comboKey, priorSolutions + 1);
                }
                
                try {
                    StringBuilder runCmd = new StringBuilder("\n\nrun { \n");
                    runCmd.append("    #Class >= 2\n");
                    if (fMinDepth > 0) runCmd.append("    some cls : Class | #(cls.^parents) >= ").append(fMinDepth).append("\n");
                    if (fMaxCoupling >= 0) runCmd.append("    all cls : Class | #{ c2 : Class - cls | coupled[cls, c2] } <= ").append(fMaxCoupling).append("\n");
                    
                    runCmd.append("} for ").append(fBitwidth).append(" but exactly ")
                          .append(c).append(" Class, ")
                          .append(m).append(" Method, ")
                          .append(a).append(" Attribute\n");
                    
                    File tempFile = File.createTempFile("alloy_gen_t" + Thread.currentThread().getId() + "_", ".als");
                    Files.write(tempFile.toPath(), (fBaseContent + runCmd.toString()).getBytes());
                    
                    A4Reporter rep = new A4Reporter();
                    Module world = CompUtil.parseEverything_fromFile(rep, null, tempFile.getAbsolutePath());
                    
                    A4Options options = new A4Options();
                    options.solver = A4Options.SatSolver.SAT4J;
                    
                    Command cmd = world.getAllCommands().get(0);
                    A4Solution ans = TranslateAlloyToKodkod.execute_command(rep, world.getAllReachableSigs(), cmd, options);
                    
                    // Advance solver past exact identically structured priors matching this thread's reserved offset
                    for (int k = 0; k < priorSolutions && ans.satisfiable(); k++) {
                        ans = ans.next();
                    }
                    
                    if (ans.satisfiable()) {
                        int currentGen = generated.incrementAndGet();
                        if (currentGen <= fTargetInstances) {
                            String metaDataString = String.format("Classes=%d, Methods=%d, Attributes=%d, MinDepth=%d, MaxCoupling=%d", c, m, a, fMinDepth, fMaxCoupling);
                            System.out.println("Found Instance #" + currentGen + " (" + metaDataString + ") [Thread-" + Thread.currentThread().getId() + "]");
                            
                            String extension = fFormat.equals("xml") ? ".xml" : ".txt";
                            String filename = "output/instance_" + currentGen + extension;
                            
                            if (fFormat.equals("xml")) {
                                ans.writeXML(filename);
                                String xmlContent = new String(Files.readAllBytes(Paths.get(filename)));
                                String meta = "\n<!-- METADATA\n  Classes: " + c + "\n  Methods: " + m + "\n  Attributes: " + a + 
                                              "\n  MinDepth: " + fMinDepth + "\n  MaxCoupling: " + fMaxCoupling + "\n-->\n";
                                xmlContent = xmlContent.replaceFirst("(<alloy[^>]*>)", "$1" + meta);
                                Files.write(Paths.get(filename), xmlContent.getBytes());
                            } else {
                                String meta = "# METADATA\n# Classes: " + c + "\n# Methods: " + m + "\n# Attributes: " + a + 
                                              "\n# MinDepth: " + fMinDepth + "\n# MaxCoupling: " + fMaxCoupling + "\n\n";
                                Files.write(Paths.get(filename), (meta + ans.toString()).getBytes());
                            }
                        }
                    }
                    
                    // Clean up trailing temp scripts
                    tempFile.delete();
                } catch (Exception e) {
                    // Fail silently for logic exceptions in individual threads and proceed to next attempt
                }
            });
        }
        
        executor.shutdown();
        executor.awaitTermination(1, TimeUnit.HOURS);
        
        int finalGenerated = generated.get();
        if (finalGenerated < targetInstances) {
            System.out.println("Finished. Could only generate " + finalGenerated + " distinct instances within combinations bounds.");
        } else {
            System.out.println("Successfully generated " + finalGenerated + " distinct varying instances globally.");
        }
        
        System.exit(0); // Forcibly clean lingering Kodkod/SAT threads blocking JVM exit
    }
}
