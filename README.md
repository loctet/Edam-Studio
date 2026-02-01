# EDAM Artifact Evaluation README

## Overview

This artifact provides a toolchain for generating smart contract code from EDAM (Extended Data-Aware Machines) specifications. The system supports both GUI-based and command-line workflows for model editing, code generation, and test generation.

## Installation
### Prerequisites
- **Python 3.10+** with pip
- **Node.js** (v16+) and npm
- **OCaml** and **opam** (OCaml package manager)
- **Z3** solver (installed via opam)

### Installation Steps
#### Linux/macOS
```bash
chmod +x install.sh
./install.sh
```

#### Windows
```cmd
install.bat
```

The installation script will:
1. Install root-level npm dependencies
2. Install GUI dependencies (`GUI/` directory)
3. Create Python virtual environment (`venv/`)
4. Install Python dependencies (Django and related packages)
5. Install OCaml packages via opam: `ocamlfind`, `z3`, `ocamlopt`

**Note**: On Windows, opam may require WSL (Windows Subsystem for Linux).

## Models

### Model Location

Predefined EDAM models are located in:
```
edams-models/edam/models/
```

### Available Models

The following models are available for code generation:

- `assettransfer` - Asset transfer contract
- `basicprovenance` - Basic provenance tracking
- `defectivecounter` - Defective counter example
- `digitallocker` - Digital locker contract
- `frequentflyer` - Frequent flyer program
- `helloblockchain` - Hello blockchain example
- `refrigeratedtransport` - Refrigerated transport tracking
- `simplemarketplace` - Simple marketplace contract
- `thermostatoperation` - Thermostat operation
- `amm` - Automated Market Maker
- `c20` - ERC-20 token contract
- `c20_2` - ERC-20 token variant
- `simplewallet` - Simple wallet contract
- `c1`, `c2`, `c3` - Example models from paper
- `cm`, `cop`, `cpay` - Additional example models

Models are defined in TypeScript/TSX format and exported from `edams-models/edam/index.ts`.

## Usage

### Method 1: GUI (Interactive)

1. **Start the API server** (Terminal 1):
   ```bash
   ./start_api.sh [port]
   ```
   Default port: 8000 (configurable in `config.json`)

2. **Start the GUI** (Terminal 2):
   ```bash
   ./start_gui.sh
   ```
   Default port: 3000

3. **Access the GUI**:
   - Open browser: http://localhost:3000
   - Select or create an EDAM model
   - Edit model using visual editor or text editor
   - Generate code via the GUI interface

**Features**:
- Visual graph editor for states and transitions
- Text-based EDAM editor
- Model import/export (JSON format)
- Code generation with downloadable results

### Method 2: CLI (Command Line)

Run from the project root directory:

```bash
source venv/bin/activate  # Activate virtual environment (Linux/macOS)
# or: venv\Scripts\activate  # Windows

python3 CLI/cli.py <model1> <model2> ... --mode <1|2|3|4> [options]
```

#### Basic Command Structure

```bash
python3 cli.py <model_names> --mode <mode> [configuration_options]
```

#### Example Commands

**Single model with default settings:**
```bash
python3 CLI/cli.py assettransfer --mode 2
```

**Multiple models:**
```bash
python3 CLI/cli.py assettransfer basicprovenance defectivecounter --mode 2
```

**With custom trace generation:**
```bash
python3 CLI/cli.py c20 amm --mode 3 --number_symbolic_traces 1000 --number_transition_per_trace 40
```

**Full configuration example:**
```bash
python3 CLI/cli.py erc20token1 erc20token2 amm --mode 3 \
  --number_symbolic_traces 500 \
  --number_transition_per_trace 100 \
  --probability_new_participant 0.35 \
  --z3_check_enabled
```

#### Generation Modes

- **Mode 1**: Basic code generation
- **Mode 2**: Enhanced generation with symbolic traces
- **Mode 3**: Advanced generation with extended traces
- **Mode 4**: Full generation with comprehensive testing

#### CLI Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--mode` | 1\|2\|3\|4 | Required | Generation mode |
| `--probability_new_participant` | float | 0.35 | Probability of new participant |
| `--probability_right_participant` | float | 0.7 | Probability of correct participant |
| `--probability_true_for_bool` | float | 0.5 | Probability for boolean true |
| `--min_int_value` | int | 0 | Minimum integer value |
| `--max_int_value` | int | 100 | Maximum integer value |
| `--max_gen_array_size` | int | 10 | Maximum array size |
| `--min_gen_string_length` | int | 5 | Minimum string length |
| `--max_gen_string_length` | int | 10 | Maximum string length |
| `--z3_check_enabled` | flag | True | Enable Z3 solver checks |
| `--number_symbolic_traces` | int | 200 | Number of symbolic traces |
| `--number_transition_per_trace` | int | 10 | Transitions per trace |
| `--number_real_traces` | int | 5 | Number of real traces |
| `--max_fail_try` | int | 2 | Maximum retry attempts |
| `--add_pi_to_test` | flag | False | Add participant info to tests |
| `--add_test_of_state` | flag | True | Add state tests |
| `--add_test_of_variables` | flag | True | Add variable tests |

## Code Generation

### Generated Output

Generated code is saved to:
```
Generated-code/
```

Each generated project includes:
- **Smart contracts** (Solidity/Move)
- **Test files** (OCaml-based test generation)
- **Configuration files** (Hardhat/Truffle configs, Move.toml)
- **Build scripts** (`run` executable)

### Generated Code Structure

```
Generated-code/
└── <ModelName>_<version>_<id>/
    ├── contracts/          # Smart contract source files
    ├── test/              # Generated test files
    ├── migrations/        # Deployment migrations
    ├── hardhat.config.js  # Hardhat configuration
    ├── package.json       # Node.js dependencies
    └── run                # Execution script
```

### Target Languages

The tool generates code for:
- **Solidity** (Ethereum smart contracts)

Target language can be specified in the generation request (default: Solidity).

## Model Processing Pipeline

1. **Model Input**: EDAM model (from GUI or predefined models)
2. **EDAM Conversion**: EDAM → EDAM representation
3. **OCaml Code Generation**: EDAM → OCaml intermediate representation
4. **Contract Generation**: OCaml → Solidity contracts
5. **Test Generation**: Symbolic execution → Test cases
6. **Output Packaging**: Generated code + tests → ZIP archive

## Configuration

### Global Configuration

Edit `config.json` to customize:
```json
{
  "api": {
    "default_port": 8000,
    "host": "127.0.0.1"
  },
  "gui": {
    "default_port": 3000
  },
  "generated_code": {
    "default_directory": "Generated-code"
  }
}
```

## Troubleshooting

### Virtual Environment Issues
```bash
# Re-run installation
./install.sh
```

### Port Conflicts
```bash
# Use custom port for API
./start_api.sh 9000

# Update GUI port in GUI/vite.config.ts
```

### opam Not Found
- **Linux/macOS**: Install from https://opam.ocaml.org/doc/Install.html
- **Windows**: Use WSL or Cygwin

### Missing Dependencies
```bash
# Reinstall Python packages
source venv/bin/activate
pip install -r API/requirements.txt

# Reinstall Node packages
cd GUI && npm install
```

## Project Structure

```
.
├── API/                    # Django backend (code generation engine)
│   ├── code_generation/    # Code generators (OCaml, Solidity, Move)
│   ├── base_code/          # OCaml base templates and utilities
│   ├── objects/            # EDAM model classes
│   └── process/            # Processing pipeline
├── GUI/                    # React frontend
│   └── src/components/     # UI components
├── CLI/                    # Command-line interface
├── edams-models/           # Predefined EDAM models
│   └── edam/models/       # Model definitions
├── Generated-code/         # Output directory for generated code
├── config.json             # Global configuration
├── install.sh              # Installation script (Linux/macOS)
├── install.bat             # Installation script (Windows)
├── start_api.sh            # API server startup script
└── start_gui.sh            # GUI startup script
```

## Quick Start Example

1. **Install**:
   ```bash
   ./install.sh
   ```

2. **Generate code via CLI**:
   ```bash
   source venv/bin/activate
   python3 CLI/cli.py assettransfer --mode 2
   ```

3. **Or use GUI**:
   ```bash
   # Terminal 1
   ./start_api.sh
   
   # Terminal 2
   ./start_gui.sh
   # Open http://localhost:3000
   ```

4. **Check output**:
   ```bash
   ls Generated-code/
   ```

## Additional Resources

- Model definitions: `edams-models/edam/models/`
- API endpoints: See `API/main.py` and `API/urls.py`
- Base code templates: `API/base_code/`