# Skeleton Instance Generator

This project is a parameterized instance generator that uses the [Alloy Analyzer 4](https://alloytools.org/) solver to generate Object-Oriented (OO) class skeletons based on the El Amrani Z metamodel.

The generated instances strictly follow the structural rules defined in the formal model. This ensures they are free of structural flaws (such as diamond problem conflicts, phantom implementations, abstract class instantiation, and illegal visibility inheritance), as verified by the Alloy solver.

## Project Structure
* `models/` - Contains the foundational formal specification `final_class_hierarchies.als`.
* `src/main/` - The Java source code for dynamically interfacing with the Alloy 4 API.
* `lib/` - Third-party dependencies (requires `alloy4.jar`).
* `output/` - The default directory where generated instances are saved in either `.xml` or `.txt` format.

## Setup Requirements
Ensure you have the following installed on your system:
* Java Runtime Environment (JRE) 8 or later
* Java Development Kit (JDK)

**Important:** You must place the `alloy4.jar` file in the `lib/` directory before building or running the project.

### Automatic Setup
We provide initialization scripts that verify your environment, create necessary directories, and compile the Java source code automatically.

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**Linux / macOS (Bash):**
```bash
./setup.sh
```

## Usage

Once compiled successfully, you can generate instances using the provided run scripts `run.sh` or `run.ps1`.

### Command Line Arguments

The generator is highly parameterized, allowing you to tightly control the volume, shape, and complexity of the generated class hierarchies:

| Argument | Description | Default |
|---|---|---|
| `--classes <int or min-max>` | The number of Classes to generate (e.g. `5` or `5-15`). | 5 |
| `--methods <int or min-max>` | The number of Methods globally distributed (e.g. `10` or `10-25`). | 6 |
| `--attributes <int or min-max>` | The number of Attributes globally distributed (e.g. `0-10`). | 4 |
| `--min-depth <int>` | The minimum required depth for at least one inheritance hierarchy tree. | 1 |
| `--max-coupling <int>` | The maximum allowed coupling (dependencies) between any two individual classes. Set to 0 to prevent cross-dependencies. | -1 (No limit) |
| `--bitwidth <int>` | The integer bitwidth capacity used by the Alloy solver. | 5 |
| `--instances <int>` | The total number of valid solutions (instances) to extract and save. | 3 |
| `--threads <int>` | The number of concurrent background threads allocated to the SAT solver. | Core count |
| `--format <xml|txt>` | The output format for the generated instances. | xml |
| `--help, -h` | Displays the help menu with all available options and defaults. | N/A |

### High-Volume Diverse Datasets (Recommended)

If you are generating datasets for training machine learning models (LLMs) or for structural analysis, we offer highly practical bulk-generation scripts (`generate_dataset`). These scripts automatically generate a high volume of unique dataset files using explicitly bounded uniform randomness.

**Key features of the `generate_dataset` scripts:**
1. **Dynamic Randomness:** The parameters are presented as bounded ranges natively (e.g. `Classes: 5-15`). No two generated instance files will be forced to use the same structural sizes.
2. **Diversity Guarantee:** The underlying Java engine uniquely tracks the randomly chosen boundaries (`C=4, M=12, A=2`) of every single generated file. If the engine ever rolls the exact same structural bounds twice during a dataset generation run, it forces the SAT solver to iterate dynamically to the next possible geometric combination (`ans = ans.next()`), guaranteeing no two outputs in your dataset have the same structural solution.
3. **Injected Metadata:** Every single output file automatically injects its *exact* resolved boundaries at the top of the file.

**Windows:**
```powershell
.\generate_dataset.ps1
```

**Linux / Mac:**
```bash
./generate_dataset.sh
```

#### Output Metadata Formats
The tool will automatically inject the metadata describing exactly how many structural elements the file was generated with:
*   **If `--format xml` (Default):** A valid XML comment is injected directly into the root tag of the output file.
    ```xml
    <alloy builddate="2009/03/19 02:02 EDT">
    <!-- METADATA
      Classes: 6
      Methods: 12
      Attributes: 4
      MinDepth: 2
      MaxCoupling: -1
    -->
    <instance bitwidth="4" ...>
    ...
    ```
*   **If `--format txt`:** A commented header is prepended to the raw text output.
    ```text
    # METADATA
    # Classes: 6
    # Methods: 12
    # Attributes: 4
    # MinDepth: 2
    # MaxCoupling: -1
    
    ---INSTANCE---
    sig Class...
    ```

**Generate 10 structured XML instances with dynamic deep inheritance:**
```bash
./run.sh --classes 5-15 --methods 10-30 --attributes 5-20 --min-depth 2 --max-coupling 3 --instances 10 --format xml
```

**Generate a quick, isolated 4-class plain text skeleton:**
```powershell
.\run.ps1 --classes 4 --methods 5 --attributes 2 --max-coupling 0 --instances 1 --format txt
```
