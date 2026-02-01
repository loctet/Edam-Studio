# EDAM Studio

A comprehensive toolchain for generating smart contract code from EDAM (Extended Data-Aware Machines) specifications. EDAM Studio provides both interactive GUI and command-line interfaces for model editing, code generation, and automated test generation.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [GUI Workflow](#gui-workflow)
  - [CLI Workflow](#cli-workflow)
  - [API Workflow](#api-workflow)
- [EDAM Models](#edam-models)
- [Code Generation](#code-generation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Features

- **Visual Model Editor**: Interactive graph-based editor for creating and editing EDAM models
- **Text-Based Editor**: Direct EDAM specification editing with syntax support
- **Multi-Model Support**: Process single or multiple EDAM models in batch
- **Smart Contract Generation**: Generate production-ready Solidity smart contracts
- **Automated Test Generation**: Symbolic execution-based test case generation
- **Multiple Workflows**: GUI, CLI, and API interfaces for different use cases
- **Predefined Models**: Library of example EDAM models for common smart contract patterns

## Prerequisites

Before installing EDAM Studio, ensure you have the following installed:

- **Python 3.10+** with pip
- **Node.js** (v16 or higher) and npm
- **OCaml** and **opam** (OCaml package manager)
- **Z3** solver (installed via opam)

### Platform-Specific Notes

- **Linux/macOS**: Full support for all features
- **Windows**: opam may require WSL (Windows Subsystem for Linux) or Cygwin

## Installation

### Automated Installation

#### Linux/macOS

```bash
chmod +x Studio/install.sh
cd Studio
./install.sh
```

#### Windows

```cmd
cd Studio
install.bat
```

The installation script performs the following steps:

1. Installs root-level npm dependencies
2. Installs GUI dependencies (`GUI/` directory)
3. Installs ReSuMo dependencies (`ReSuMo/` directory)
4. Creates Python virtual environment (`venv/`)
5. Installs Python dependencies (Django and related packages)
6. Installs OCaml packages via opam: `ocamlfind`, `z3`, `ocamlopt`
7. Updates `config.json` with ReSuMo absolute path

### Manual Installation

If you prefer manual installation or need to troubleshoot:

```bash
# 1. Install root dependencies
npm install

# 2. Install GUI dependencies
cd GUI && npm install && cd ..

# 3. Install ReSuMo dependencies
cd ReSuMo && npm install && cd ..

# 4. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 5. Install Python dependencies
pip install --upgrade pip
pip install -r API/requirements.txt

# 6. Install OCaml packages
opam init --yes --disable-sandboxing
opam install ocamlfind z3 ocaml-base-compiler --yes
eval $(opam env)
```

## Quick Start

### Generate Code via CLI

```bash
cd Studio
source venv/bin/activate  # On Windows: venv\Scripts\activate
python3 CLI/cli.py assettransfer --mode 2
```

### Use the GUI

```bash
cd Studio

# Terminal 1: Start API server
./start_api.sh

# Terminal 2: Start GUI
./start_gui.sh

# Open browser: http://localhost:3000
```

## Usage

### GUI Workflow

The GUI provides an interactive environment for model editing and code generation.

#### Starting the Services

1. **Start the API server** (Terminal 1):
   ```bash
   cd Studio
   ./start_api.sh [port]
   ```
   Default port: 5000 (configurable in `config.json`)

2. **Start the GUI** (Terminal 2):
   ```bash
   cd Studio
   ./start_gui.sh
   ```
   Default port: 3000

3. **Access the GUI**:
   - Open your browser: http://localhost:3000
   - Select or create an EDAM model
   - Edit model using visual graph editor or text editor
   - Generate code via the interface
   - Download generated code as ZIP archive

#### GUI Features

- **Visual Graph Editor**: Drag-and-drop interface for states and transitions
- **Text Editor**: Direct EDAM specification editing
- **Model Import/Export**: JSON format support
- **Code Generation**: One-click code generation with downloadable results
- **Model Library**: Access to predefined EDAM models

### CLI Workflow

The command-line interface is ideal for batch processing and automation.

#### Basic Command Structure

```bash
cd Studio
source venv/bin/activate  # On Windows: venv\Scripts\activate
python3 CLI/cli.py <model1> <model2> ... --mode <1|2|3|4> [options]
```

The CLI accepts both:
- **Model names** (predefined models from `edams-models/`)
- **`.edam` file paths** (text-based EDAM specifications)

#### Examples

**Single model with default settings:**
```bash
python3 CLI/cli.py assettransfer --mode 2
```

**Using a .edam file:**
```bash
python3 CLI/cli.py my_model.edam --mode 2
```

**Multiple models (mix of names and files):**
```bash
python3 CLI/cli.py assettransfer basicprovenance my_custom.edam --mode 2
```

**Custom trace generation:**
```bash
python3 CLI/cli.py c20 amm --mode 3 \
  --number_symbolic_traces 1000 \
  --number_transition_per_trace 40
```

**Full configuration example:**
```bash
python3 CLI/cli.py erc20token1 erc20token2 amm --mode 3 \
  --number_symbolic_traces 500 \
  --number_transition_per_trace 100 \
  --probability_new_participant 0.35 \
  --z3_check_enabled
```

#### .edam File Format

The `.edam` file format is a text-based representation of EDAM models:

```
ModelName
Role1,Role2,Role3
variable1:type1, variable2:type2
[from_state] {userVar:role:mode}, guard, [external_calls] callerVar:operation(params){assignments} {user:role:mode} [to_state]
```

**Example .edam file:**
```
SimpleCounter

O,R

counter:int, max:int

[_] {}, max>x, [] p:start(x:int, max:int){counter=x} {p:O:Top} [q1]

[q1] {p1:O:Bottom, p1:B:Bottom}, counter<max, [C2.test(counter+1)] p1:inc() {counter = counter +1} {p1:B:Top} [q1]

[q1] {p:O:Top}, counter >= max, [] p1:close() {} {} [q2]
```

#### Generation Modes

- **Mode 1**: Basic code generation
- **Mode 2**: Enhanced generation with symbolic traces (recommended)
- **Mode 3**: Advanced generation with extended traces
- **Mode 4**: Full generation with comprehensive testing

#### CLI Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--mode` | 1\|2\|3\|4 | **Required** | Generation mode |
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

### API Workflow

The API provides programmatic access to code generation functionality.

#### Endpoints

- **POST** `/api/convert-bulk`: Generate code from EDAM models
- **GET** `/api/download/<file_name>`: Download generated code
- **POST** `/api/run-test/<file_name>`: Run tests on generated code

#### Example API Request

```bash
curl -X POST http://localhost:5000/api/convert-bulk \
  -H "Content-Type: application/json" \
  -d '{
    "models": [...],
    "target_language": "solidity"
  }'
```

## EDAM Models

### Model Location

Predefined EDAM models are located in:
```
Studio/edams-models/edam/models/
```

### Available Models

The following models are available for code generation:

#### Smart Contract Examples
- `assettransfer` - Asset transfer contract
- `basicprovenance` - Basic provenance tracking
- `digitallocker` - Digital locker contract
- `frequentflyer` - Frequent flyer program
- `refrigeratedtransport` - Refrigerated transport tracking
- `simplemarketplace` - Simple marketplace contract
- `thermostatoperation` - Thermostat operation

#### DeFi Examples
- `amm` - Automated Market Maker
- `c20` - ERC-20 token contract
- `c20_2` - ERC-20 token variant
- `simplewallet` - Simple wallet contract

#### Research Examples
- `c1`, `c2`, `c3` - Example models from paper
- `cm`, `cop`, `cpay` - Additional example models
- `defectivecounter` - Defective counter example
- `helloblockchain` - Hello blockchain example

Models are defined in TypeScript/TSX format and exported from `edams-models/edam/index.ts`.

## Code Generation

### Generated Output

Generated code is saved to:
```
Studio/Generated-code/
```

Each generated project includes:
- **Smart contracts** (Solidity)
- **Test files** (OCaml-based test generation)
- **Configuration files** (Hardhat configs, package.json)
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

Currently supported:
- **Solidity** (Ethereum smart contracts)

### Model Processing Pipeline

1. **Model Input**: EDAM model (from GUI or predefined models)
2. **EDAM Conversion**: EDAM → Internal representation
3. **OCaml Code Generation**: EDAM → OCaml intermediate representation
4. **Contract Generation**: OCaml → Solidity contracts
5. **Test Generation**: Symbolic execution → Test cases
6. **Output Packaging**: Generated code + tests → ZIP archive

## Configuration

### Global Configuration

Edit `Studio/config.json` to customize settings:

```json
{
  "api": {
    "default_port": 5000,
    "host": "127.0.0.1"
  },
  "gui": {
    "default_port": 3000
  },
  "generated_code": {
    "default_directory": "Generated-code"
  },
  "sumo": {
    "absolute_sumo_dir": "/path/to/ReSuMo"
  }
}
```

### Configuration Options

- `api.default_port`: Default port for the API server
- `api.host`: Host address for the API server
- `gui.default_port`: Default port for the GUI (also check `GUI/vite.config.ts`)
- `generated_code.default_directory`: Directory where generated code is saved
- `sumo.absolute_sumo_dir`: Absolute path to ReSuMo directory

## Project Structure

```
Studio/
├── API/                    # Django backend (code generation engine)
│   ├── code_generation/    # Code generators (OCaml, Solidity)
│   ├── code_generators/    # Language-specific generators
│   ├── base_code/          # OCaml base templates and utilities
│   ├── objects/            # EDAM model classes
│   ├── process/            # Processing pipeline
│   ├── main.py             # API endpoints
│   └── requirements.txt    # Python dependencies
├── GUI/                    # React frontend
│   ├── src/
│   │   ├── components/     # UI components
│   │   └── pages/          # Page components
│   └── package.json        # Node.js dependencies
├── CLI/                    # Command-line interface
│   ├── cli.py              # Main CLI script
│   ├── cli_commands.py     # CLI command handlers
│   └── payload_generator.js # Model payload generator
├── edams-models/           # Predefined EDAM models
│   └── edam/
│       ├── models/         # Model definitions
│       └── index.ts        # Model exports
├── ReSuMo/                 # ReSuMo analysis tool
├── Generated-code/         # Output directory for generated code
├── venv/                   # Python virtual environment
├── config.json             # Global configuration
├── install.sh              # Installation script (Linux/macOS)
├── install.bat             # Installation script (Windows)
├── start_api.sh            # API server startup script
├── start_api.bat           # API server startup script (Windows)
├── start_gui.sh            # GUI startup script
└── start_gui.bat           # GUI startup script (Windows)
```

## Troubleshooting

### Virtual Environment Issues

```bash
# Re-run installation
cd Studio
./install.sh
```

### Port Conflicts

```bash
# Use custom port for API
cd Studio
./start_api.sh 9000

# Update GUI port in GUI/vite.config.ts and config.json
```

### opam Not Found

- **Linux/macOS**: Install from https://opam.ocaml.org/doc/Install.html
  ```bash
  curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh | sh
  ```
- **Windows**: Use WSL or Cygwin

### Missing Dependencies

```bash
# Reinstall Python packages
cd Studio
source venv/bin/activate
pip install -r API/requirements.txt

# Reinstall Node packages
cd GUI && npm install
cd ../ReSuMo && npm install
```

### OCaml Environment Issues

```bash
# Initialize opam environment
eval $(opam env)

# Verify OCaml packages
opam list
```

### Permission Issues

```bash
# Make scripts executable
chmod +x Studio/*.sh
chmod +x Studio/CLI/*.sh
```

## Additional Resources

- **Model definitions**: `Studio/edams-models/edam/models/`
- **API endpoints**: See `Studio/API/main.py` and `Studio/API/urls.py`
- **Base code templates**: `Studio/API/base_code/`
- **CLI documentation**: See `Studio/CLI/cli.py` and `Studio/CLI/cli_commands.py`
- **GUI components**: `Studio/GUI/src/components/`

## License

See [LICENSE](LICENSE) file for details.
