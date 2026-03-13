#!/bin/bash

echo "========================================="
echo " Skeleton Generator Setup Script (Linux)"
echo "========================================="

# Check for Java Runtime
if ! command -v java &> /dev/null; then
    echo "[!] ERROR: Java is not installed or not in PATH."
    echo "    Please install Java 8 or newer and try again."
    exit 1
fi

# Check for Java Compiler
if ! command -v javac &> /dev/null; then
    echo "[!] ERROR: Java Compiler (javac) is not installed."
    echo "    Please install a JDK (Java Development Kit) and try again."
    exit 1
fi

echo "[✔] Java runtime and compiler detected."

# Check for Alloy 4 dependency
if [ ! -f "lib/alloy4.jar" ]; then
    echo "[!] ERROR: alloy4.jar not found in the lib/ folder."
    echo "    Please ensure you have placed alloy4.jar in the lib/ directory before running."
    exit 1
fi

echo "[✔] alloy4.jar found."

# Create output folder if missing
mkdir -p output
echo "[✔] Output directory ready."

# Compile the InstanceGenerator
echo "[...] Compiling Java source files..."
javac -cp "lib/alloy4.jar" src/main/InstanceGenerator.java

if [ $? -eq 0 ]; then
    echo "[✔] Compilation successful!"
    echo ""
    echo "Setup is complete. You can now use the generator via:"
    echo "  ./run.sh --classes 5 --instances 3 --format xml"
else
    echo "[!] ERROR: Compilation failed. Please check the source code."
    exit 1
fi
