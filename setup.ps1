Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Skeleton Generator Setup Script (Win)  " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check for Java Runtime
if (-Not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "[!] ERROR: Java is not installed or not in PATH." -ForegroundColor Red
    Write-Host "    Please install Java 8 or newer and try again."
    exit 1
}

# Check for Java Compiler
if (-Not (Get-Command javac -ErrorAction SilentlyContinue)) {
    Write-Host "[!] ERROR: Java Compiler (javac) is not installed." -ForegroundColor Red
    Write-Host "    Please install a JDK (Java Development Kit) and try again."
    exit 1
}

Write-Host "[✔] Java runtime and compiler detected." -ForegroundColor Green

# Check for Alloy 4 dependency
if (-Not (Test-Path "lib\alloy4.jar")) {
    Write-Host "[!] ERROR: alloy4.jar not found in the lib\ folder." -ForegroundColor Red
    Write-Host "    Please ensure you have placed alloy4.jar in the lib\ directory before running."
    exit 1
}

Write-Host "[✔] alloy4.jar found." -ForegroundColor Green

# Create output folder if missing
if (-Not (Test-Path "output")) {
    New-Item -ItemType Directory -Path "output" | Out-Null
}
Write-Host "[✔] Output directory ready." -ForegroundColor Green

# Compile the InstanceGenerator
Write-Host "[...] Compiling Java source files..." -ForegroundColor Yellow
javac -cp "lib\alloy4.jar" src\main\InstanceGenerator.java

if ($LASTEXITCODE -eq 0) {
    Write-Host "[✔] Compilation successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Setup is complete. You can now use the generator via:"
    Write-Host "  .\run.ps1 --classes 5 --instances 3 --format xml" -ForegroundColor Cyan
} else {
    Write-Host "[!] ERROR: Compilation failed. Please check the source code." -ForegroundColor Red
    exit 1
}
