% EDAM Studio — Full Documentation
% Auto-generated documentation
% EDAM Studio Project

---

# EDAM Studio — Full Documentation

A comprehensive toolchain for generating smart contract code from EDAM (Extended Data-Aware Machines) specifications. EDAM Studio provides both interactive GUI and command-line interfaces for model editing, code generation, and automated test generation.

> **Navigable documentation:** For iterative, file-by-file documentation with functions and parameters, see [index.html](index.html).

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Quick Start](#quick-start)
6. [How to Run](#how-to-run)
7. [Usage](#usage)
8. [API Reference](#api-reference)
9. [CLI Reference](#cli-reference)
10. [GUI Components](#gui-components)
11. [EDAM Models](#edam-models)
12. [Code Generation](#code-generation)
13. [Complete Flow: EDAM → Code → Test](#complete-flow-edam--code--test)
14. [OCaml Files Reference](#ocaml-files-reference)
15. [Scripts Reference](#scripts-reference)
16. [Configuration](#configuration)
17. [Project Structure](#project-structure)
18. [Docker Deployment](#docker-deployment)
19. [Troubleshooting](#troubleshooting)
20. [Additional Resources](#additional-resources)

---

## Overview

EDAM Studio is a multi-component system that transforms formal EDAM specifications into production-ready Solidity smart contracts. The system comprises:

- **API** — Django backend providing REST endpoints for code generation
- **GUI** — React/Vite frontend with visual and text-based model editors
- **CLI** — Command-line interface for batch processing and automation
- **ReSuMo** — Symbolic execution engine for test generation
- **edams-models** — Library of predefined EDAM model templates

---

## Features

- **Visual Model Editor**: Interactive graph-based editor for creating and editing EDAM models
- **Text-Based Editor**: Direct EDAM specification editing with syntax support
- **Multi-Model Support**: Process single or multiple EDAM models in batch
- **Smart Contract Generation**: Generate production-ready Solidity smart contracts
- **Automated Test Generation**: Symbolic execution-based test case generation
- **Multiple Workflows**: GUI, CLI, and API interfaces for different use cases
- **Predefined Models**: Library of example EDAM models for common smart contract patterns

---

## Prerequisites

Before installing EDAM Studio, ensure you have the following installed:

| Requirement | Version |
|-------------|---------|
| Python | 3.10+ with pip |
| Node.js | v16 or higher |
| npm | (bundled with Node.js) |
| OCaml | with opam (package manager) |
| Z3 solver | installed via opam |

### Platform-Specific Notes

- **Linux/macOS**: Full support for all features
- **Windows**: opam may require WSL (Windows Subsystem for Linux) or Cygwin

---

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

### What the Installation Script Does

1. Installs root-level npm dependencies
2. Installs GUI dependencies (`GUI/` directory)
3. Installs ReSuMo dependencies (`ReSuMo/` directory)
4. Creates Python virtual environment (`venv/`)
5. Installs Python dependencies (Django and related packages)
6. Installs OCaml packages via opam: `ocamlfind`, `z3`, `ocamlopt`
7. Updates `config.json` with ReSuMo absolute path

### Manual Installation

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

---

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

---

## How to Run

This section describes how to run EDAM Studio for each workflow. All commands assume you are in the project root directory unless otherwise noted.

### Running the CLI

**Linux/macOS:**

```bash
cd Studio
source venv/bin/activate
python3 CLI/cli.py assettransfer --mode 2
```

**Windows:**

```cmd
cd Studio
venv\Scripts\activate
python3 CLI/cli.py assettransfer --mode 2
```

The CLI requires the Python virtual environment to be activated. Replace `assettransfer` with any model name from `edams-models/` or a path to a `.edam` file.

### Running the GUI

The GUI requires two processes: the API server and the GUI frontend. Use two separate terminals.

**Terminal 1 — Start the API server**

| Platform   | Command                    |
|------------|----------------------------|
| Linux/macOS| `cd Studio && ./start_api.sh [port]` |
| Windows    | `cd Studio` then `start_api.bat`     |

Default API port: **5000** (configurable in `config.json`).

**Terminal 2 — Start the GUI**

| Platform   | Command                    |
|------------|----------------------------|
| Linux/macOS| `cd Studio && ./start_gui.sh` |
| Windows    | `cd Studio` then `start_gui.bat`   |

Default GUI port: **3000**.

**Access the GUI:** Open your browser at [http://localhost:3000](http://localhost:3000).

### Running via API

1. Start the API server (see [Running the GUI](#running-the-gui) — Terminal 1).
2. Send requests to `http://localhost:5000` (or your configured port).

Example:

```bash
curl -X POST http://localhost:5000/api/convert-bulk \
  -H "Content-Type: application/json" \
  -d '{"models": [...], "target_language": "solidity"}'
```

### Running with Docker

```bash
cd Docker
docker compose up --build
```

- **GUI**: http://localhost:3000  
- **API**: http://localhost:5000  

CLI inside the container:

```bash
docker exec -it edam-studio edam-cli assettransfer --mode 2
```

---

## Usage

### GUI Workflow

1. **Start the API server** (Terminal 1): `./start_api.sh [port]`
2. **Start the GUI** (Terminal 2): `./start_gui.sh`
3. **Access**: http://localhost:3000
4. Select or create an EDAM model, edit, generate code, download ZIP

#### GUI Features

- **Visual Graph Editor**: Drag-and-drop interface for states and transitions
- **Text Editor**: Direct EDAM specification editing
- **Model Import/Export**: JSON format support
- **Code Generation**: One-click generation with downloadable results

### CLI Workflow

```bash
cd Studio
source venv/bin/activate
python3 CLI/cli.py <model1> <model2> ... --mode <1|2|3|4> [options]
```

#### .edam File Format

```
ModelName
Role1,Role2,Role3
variable1:type1, variable2:type2
[from_state] {userVar:role:mode}, guard, [external_calls] callerVar:operation(params){assignments} {user:role:mode} [to_state]
```

#### Generation Modes

| Mode | Description |
|------|-------------|
| 1 | Basic code generation |
| 2 | Enhanced generation with symbolic traces (recommended) |
| 3 | Advanced generation with extended traces |
| 4 | Full generation with comprehensive testing |

---

## API Reference

### Base URL

- Default: `http://localhost:5000`
- Configurable in `config.json`

### Endpoints

#### POST `/api/convert-bulk`

Generate code from EDAM models.

**Request Body:**

```json
{
  "models": [...],
  "target_language": "solidity"
}
```

**Response:** JSON with generation results and download information.

**Errors:**

- `405`: Only POST method allowed
- `400`: Expected an array of EDAMs

---

#### POST `/api/execute-edam-trace`

Execute EDAM trace.

**Request Body:**

```json
{
  "models": [...]
}
```

**Response:** Trace execution results.

---

#### GET `/api/download-file/<file_name>/`

Download a generated file (e.g., ZIP archive).

**Parameters:**

- `file_name` — Name of the file to download

**Response:** File attachment.

**Errors:**

- `404`: File not found
- `500`: Server error

---

#### GET `/api/run-test-file/<file_name>/`

Run tests on generated code. If the folder does not exist, unzips the file and runs `./run` in the folder.

**Parameters:**

- `file_name` — Name of the generated ZIP file

**Response:**

```json
{
  "data": "<test output>"
}
```

**Errors:**

- `404`: File not found
- `500`: npm install or test command failed

---

### Example API Request

```bash
curl -X POST http://localhost:5000/api/convert-bulk \
  -H "Content-Type: application/json" \
  -d '{
    "models": [...],
    "target_language": "solidity"
  }'
```

---

## CLI Reference

### Command Structure

```bash
python3 CLI/cli.py <MODEL> [MODEL ...] --mode {1,2,3,4} [options]
```

### Positional Arguments

| Argument | Description |
|----------|-------------|
| MODEL | Model name (from edams-models) or path to `.edam` file |

### Required Options

| Option | Values | Description |
|--------|--------|-------------|
| `--mode` | 1, 2, 3, 4 | Generation mode |

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
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

### Examples

```bash
# Single model
python3 CLI/cli.py assettransfer --mode 2

# Using .edam file
python3 CLI/cli.py my_model.edam --mode 2

# Multiple models
python3 CLI/cli.py assettransfer basicprovenance my_custom.edam --mode 2

# Custom trace generation
python3 CLI/cli.py c20 amm --mode 3 \
  --number_symbolic_traces 1000 \
  --number_transition_per_trace 40
```

---

## GUI Components

### Component Structure

```
GUI/src/
├── components/
│   ├── edam/           # EDAM-specific components
│   │   ├── EDAMEditor.tsx
│   │   ├── EDAMGraph.tsx
│   │   ├── EDAMGraphviz.tsx
│   │   ├── EDAMHeader.tsx
│   │   ├── EDAMJsonEditor.tsx
│   │   ├── EDAMSidebar.tsx
│   │   ├── EDAMTextEditor.tsx
│   │   ├── CodeGenerationResults.tsx
│   │   ├── ConfigModal.tsx
│   │   ├── HelpModal.tsx
│   │   ├── NewModelModal.tsx
│   │   ├── StateModal.tsx
│   │   ├── TraceTestModal.tsx
│   │   ├── TransitionModal.tsx
│   │   └── utils/
│   └── ui/             # Reusable UI components (shadcn/ui)
├── pages/
│   ├── Index.tsx
│   └── NotFound.tsx
├── hooks/
├── lib/
└── main.tsx
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `EDAMEditor` | Main editor container |
| `EDAMGraph` | Visual graph-based model editor |
| `EDAMTextEditor` | Text-based EDAM specification editor |
| `EDAMJsonEditor` | JSON representation editor |
| `CodeGenerationResults` | Display and download generated code |
| `ConfigModal` | Configuration settings |
| `TraceTestModal` | Trace and test execution |

---

## EDAM Models

### Model Location

```
Studio/edams-models/edam/models/
```

### Available Models

#### Smart Contract Examples

- `assettransfer` — Asset transfer contract
- `basicprovenance` — Basic provenance tracking
- `digitallocker` — Digital locker contract
- `frequentflyer` — Frequent flyer program
- `refrigeratedtransport` — Refrigerated transport tracking
- `simplemarketplace` — Simple marketplace contract
- `thermostatoperation` — Thermostat operation

#### DeFi Examples

- `amm` — Automated Market Maker
- `c20` — ERC-20 token contract
- `c20_2` — ERC-20 token variant
- `simplewallet` — Simple wallet contract

#### Research Examples

- `cm`, `cop`, `cpay` — Example models
- `defectivecounter` — Defective counter example
- `helloblockchain` — Hello blockchain example

---

## Code Generation

### Generated Output Location

```
Studio/Generated-code/
```

### Generated Structure

```
Generated-code/
└── <ModelName>_<version>_<id>/
    ├── contracts/          # Smart contract source files
    ├── test/               # Generated test files
    ├── migrations/         # Deployment migrations
    ├── hardhat.config.js   # Hardhat configuration
    ├── package.json        # Node.js dependencies
    └── run                 # Execution script
```

### Target Languages

- **Solidity** (Ethereum smart contracts)

---

## Complete Flow: EDAM → Code → Test

This section describes the end-to-end pipeline from EDAM specification to generated Solidity contracts and automated tests.

### Flow Diagram

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  EDAM Input     │     │  Python/Node     │     │  OCaml Engine   │
│  (GUI/CLI/API)  │────▶│  Payload/Process │────▶│  (base_code/)   │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
        │                           │                      │
        │                           │                      ▼
        │                           │             ┌──────────────────┐
        │                           │             │  Python EDAM       │
        │                           │             │  (intermediate)    │
        │                           │             └────────┬──────────┘
        │                           │                      │
        │                           ▼                      ▼
        │                  ┌──────────────────┐    ┌──────────────────┐
        │                  │  Solidity        │◀───│  Test Generation │
        │                  │  Contract Gen    │    │  (OCaml + Z3)    │
        │                  └────────┬────────┘    └──────────────────┘
        │                            │
        ▼                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Output: contracts/*.sol + test/*.js + run script + ZIP             │
└─────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Flow

#### Step 1: EDAM Input

- **GUI**: User edits model in visual/text editor → JSON sent to API
- **CLI**: `payload_generator.js` converts model names or `.edam` files → `output.json`
- **API**: Receives `{ models: [...], server_settings: {...} }`

#### Step 2: Python Process (`process/process.py`)

- `CodeGenerationProcess._process_models()` iterates over each EDAM
- For each EDAM: `ocaml_generator.generate_code(edam, server_settings)`
- OCaml generator writes EDAM to OCaml file, runs `ocaml <file>.ml` → produces Python EDAM string
- Python EDAM is `eval()`'d and passed to `contract_generator.generate_code()`
- Solidity contracts are generated
- `contract_generator.generate_test_code()` invokes OCaml test generation

#### Step 3: OCaml Code Generation (EDAM → Python EDAM)

- **File**: `ocaml_base_code.ml` + EDAM code injected
- **Execution**: `ocaml <uid>.ml` prints Python EDAM representation to stdout
- **Output**: Python `EDAM(...)` and `Transition(...)` objects as text
- **Key function**: `generate_python_edam` in `ocaml_base_code.ml` converts OCaml `edam_type` to Python syntax

#### Step 4: OCaml Test Generation (Symbolic Traces → Hardhat Tests)

- **File**: `ocaml_test_code.ml` (template with `{edams_code_here}` replaced)
- **Compilation**: `cmd_run.sh` compiles `types.ml`, `printer.ml`, `helper.ml`, `z3_module.ml`, `core_functions.ml`, `test_generation.ml`, `{file}.ml`
- **Execution**: `./generate_test{file_name}` runs the compiled binary
- **Process**:
  1. `generate_random_trace()` creates symbolic traces (random transition sequences)
  2. For each symbolic trace, `generate_real_traces_from_symbolic()` instantiates with Z3 (guard satisfiability) or random values
  3. `evaluate_trace()` executes each trace and records success/failure
  4. `generate_hardhat_tests()` emits JavaScript/Chai test code
- **Output**: Migration code + test code printed to stdout, captured by Python

#### Step 5: Solidity Contract Generation

- Python `ContractCodeGenerator` (in `code_generators/solidity/`) consumes the Python EDAM representation
- Produces `.sol` files with state machine, role checks, and transition logic

#### Step 6: Output Packaging

- `create_zip_file()` bundles contracts, tests, configs, and `run` script into a ZIP

---

## OCaml Files Reference

All OCaml source files reside in `Studio/API/base_code/`. They form the symbolic execution and test generation engine.

### File Overview

| File | Purpose |
|------|---------|
| `types.ml` | Type definitions for EDAM, transitions, configurations |
| `helper.ml` | Evaluation, sigma/iota, random value generation |
| `printer.ml` | Debug/pretty-print for traces, sigma, transitions |
| `core_functions.ml` | Transition checking, trace evaluation |
| `z3_module.ml` | Z3 SMT conversion and guard satisfiability |
| `test_generation.ml` | Trace generation, Hardhat test emission |
| `ocaml_base_code.ml` | EDAM → Python EDAM conversion |
| `ocaml_to_json.ml` | Alternative EDAM → JSON (standalone) |
| `ocaml_test_code.ml` | Template for test generation (placeholders) |
| `ocaml_trace_test_run_base_code.ml` | Template for trace execution |
| `trace_cm_c20.ml` | Example hardcoded C20 + CM trace test |

### types.ml — Type Definitions

| Type | Description |
|------|-------------|
| `ptp_var` | Participant variable: `Ptp of string` |
| `participant` | Participant ID: `PID of string` |
| `role_type` | Role: `Role of string` |
| `role_mode` | Top \| Bottom \| Unknown |
| `operation` | Operation name: `Operation of string` |
| `dvar` | Data variable: `Var of string` |
| `value_type` | BoolVal, IntVal, StrVal, PtpID, ListVal, MapVal |
| `exp` | Expression AST (arithmetic, boolean, FuncCall, FuncCallEdamRead) |
| `funcCallEdamWrite` | External EDAM call: `FuncCallEdamWrite of string * operation * exp list * exp list` |
| `z3_exp` | Z3 expression: Z_Exp, Z_Call, Z_And, Z_Eq |
| `guard_type` | `exp * (funcCallEdamWrite * bool) list` |
| `label_type` | guard, rho, ptp, op, ptp_list, dvar_list, assignments, rho', name |
| `label_conf` | `participant * operation * participant list * value_type list` |
| `configuration` | state, pi, sigma |
| `edam_type` | name, states, transitions, final_modes, initial_state, roles_list, ptp_var_list, variables_list |
| `multi_config` | edam_map, config_map (Hashtbl) |
| `server_config_type` | Probabilities, bounds, Z3 flag, add_pi_to_test, etc. |
| `dependancy_type` | required_calls, participant_roles, can_generate_participants, transition_probabilities |

### helper.ml — Functions

| Function | Description |
|----------|-------------|
| `find_with_debug` | Safe Hashtbl lookup with error message |
| `copy_sigma` | Deep copy of sigma |
| `sort_states`, `sort_roles` | Sort state/role lists |
| `get_state_index`, `get_roles_index` | Index of state/role in sorted list |
| `generate_iota` | Build iota from ptp_list and participants |
| `generate_iota_from_label` | Build iota from label_conf and multi_cfg |
| `parse_index` | Parse "int"/"str"/"pid"/"bool" index |
| `initialize_sigma` | Create sigma from variable list with defaults |
| `copy_multi_config` | Deep copy of multi_config |
| `substitute_values` | Update sigma with (dvar, value) list |
| `update_map`, `update_nested_map` | Map update helpers |
| `eval` | Evaluate expression under sigma, iota, multi_cfg |
| `external_function_call` | Built-ins: sum, append, length, update_map, get_amount_out, etc. |
| `external_edam_read` | Read variable from another EDAM |
| `external_edam_write` | Call transition on another EDAM |
| `eval_func_write_list` | Evaluate list of FuncCallEdamWrite |
| `generate_random_value` | Random value by dvar_type and server_configs |
| `select_valid_transition` | Probabilistic transition selection |
| `eval_command` | Eval commands: var, sum, count, get state, countRole, etc. |
| `get_edam_config` | Get edam and config from multi_cfg |
| `remove_duplicates`, `random_select` | List utilities |
| `get_timestamp`, `count_operation_occurrences`, `get_operations_before`, etc. | Log/analysis helpers |

### printer.ml — Functions

| Function | Description |
|----------|-------------|
| `sigma_contains` | Check if variable in sigma |
| `string_of_value` | value_type → string |
| `print_participants_list`, `print_roles_list` | Print participants/roles |
| `print_participants_and_roles` | Print config pi for ptp_vars |
| `print_map`, `print_sigma` | Print map/sigma contents |
| `print_all_sigmas` | Print sigma for all EDAMs in multi_cfg |
| `print_transition_details` | Print transition with iota, sigma |
| `print_symbolic_trace`, `print_trace` | Print trace for debugging |

### core_functions.ml — Functions

| Function | Description |
|----------|-------------|
| `update_pi` | Update pi from rho, rho', iota, party_list |
| `bowtie` | Check role mode compatibility across participants |
| `role_satisf` | Check pi models iota and rho |
| `update_iota` | Update iota with (ptp_var, participant) list |
| `validate_edams` | Check EDAM validity (start transition, etc.) |
| `check_transition` | Validate transition against config, return new config or error |
| `perform_transition_impl` | Execute transition, update multi_cfg, handle reentrancy |
| `evaluate_trace` | Run trace, return (result_trace, updated_multi_cfg) |
| `evaluate_trace_last` | Evaluate last segment, append to previous trace |

### z3_module.ml — Functions

| Function | Description |
|----------|-------------|
| `guard_to_z3_exp` | Convert guard_type to z3_exp |
| `build_dvar_map` | Map dvar_list to values |
| `substitute_params` | Substitute dvar/ptp in z3_exp |
| `replace_dvars` | Replace Dvar with sigma values in z3_exp |
| `z3_of_z3_exp` | Convert z3_exp to Z3.Expr |
| `z3_of_exp` | Convert exp to Z3.Expr (ints, bools, strings, arithmetic, etc.) |
| `z3_of_func_write` | Convert FuncCallEdamWrite to Z3 (nested calls) |
| `check_guard_satisfiability` | Run Z3 solver on guard, return status and model bindings |

### test_generation.ml — Functions

| Function | Description |
|----------|-------------|
| `update_participant_roles_in_dependancy` | Update dependency participant_roles from config |
| `generate_new_participant` | Create new PID for role |
| `select_or_generate_participant` | Choose existing or generate new by probability |
| `get_role` | Get role for user from rho |
| `getParticipantsIds` | Get participant IDs for ptp_list from dependencies |
| `find_participants_for_ptp` | Filter participants by rho Top/Bottom |
| `getOrGenParticipantsIds` | Get or generate participants for ptp_list |
| `generate_random_trace` | Symbolic trace + real traces via Z3/random |
| `generate_pi_tests` | Emit Hardhat assertions for role permissions |
| `get_params_str` | Format parameters for test calls |
| `extract_dependencies_from_transition` | Get called EDAMs from transition |
| `compute_edam_deployment_order` | Topological sort for deployment |
| `generate_deployment_logic` | Generate deployment code for trace |
| `generate_hardhat_tests` | Main: emit full Hardhat/Chai test suite |

### ocaml_base_code.ml — Functions

| Function | Description |
|----------|-------------|
| `guard_to_z3_exp` | guard_type → z3_exp |
| `generate_ptp_roles_modes` | rho, ptp_vars, roles → JSON string |
| `value_type_to_text` | value_type → string |
| `exp_to_text`, `exp_to_text_helper` | exp → Python-like string |
| `list_calls_to_text` | list of calls → string |
| `generate_python_edam` | edam_type → Python EDAM(...) string |
| `validate_edams` | Validate EDAM structure |

### ocaml_test_code.ml — Template

Placeholders replaced by Python:

- `{edams_code_here}` — EDAM instances, configurations, dependencies_map
- `{probability_new_participant}`, `{number_symbolic_traces}`, etc. — server_settings

Flow: `Random.self_init()` → for each trace index, `generate_random_trace` → `evaluate_trace` → `generate_hardhat_tests` → print migration and test code.

### ocaml_trace_test_run_base_code.ml — Template

Placeholders:

- `{edams_code_here}` — EDAM code
- `{call_list_here}` — `let calls_list = [ ... ]`

Used for trace execution (e.g. API trace test): runs `evaluate_trace` on given calls and prints result.

---

## Scripts Reference

### Studio Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `install.sh` | Studio/ | Full installation (npm, venv, opam, config) |
| `install.bat` | Studio/ | Windows installation |
| `start_api.sh` | Studio/ | Start Django API server |
| `start_api.bat` | Studio/ | Windows: start API |
| `start_gui.sh` | Studio/ | Start Vite GUI |
| `start_gui.bat` | Studio/ | Windows: start GUI |
| `cli.sh` | Studio/CLI/ | CLI wrapper |

### API base_code Scripts

| Script | Purpose |
|--------|---------|
| `cmd_run.sh` | Compile OCaml test generator (types, printer, helper, z3_module, core_functions, test_generation, {file_name}) and run `./generate_test{file_name}` |
| `cmd_test_run_cm_c20.sh` | Example: compile and run `trace_cm_c20.ml` for C20+CM trace test |

Placeholders in `cmd_run.sh`: `{uid}`, `{file_name}`.

### Docker Scripts

| Script | Purpose |
|--------|---------|
| `build.sh` | Build Docker image |
| `load-docker.sh` | Load image from tar.gz |
| `push-image.sh` | Push image to registry |

### ReSuMo Scripts

| Script | Purpose |
|--------|---------|
| `process_zip_files.sh` | Process ZIP files (batch) |
| `process_zip_files_1.sh`, `2.sh`, `3.sh` | Variants |
| `process_zip_files_T_AMM*.sh` | AMM-specific processing |
| `process_zip_files_Test_T_Token_*.sh` | Token-specific processing |
| `process_zip_files_move.sh` | Move/process |
| `runExcelMerge.sh` | Merge Excel results |
| `merger_to_one_excel_recap.py` | Python: merge Excel recap |

---

## Configuration

### config.json Structure

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

| Option | Description |
|--------|-------------|
| `api.default_port` | Default port for API server |
| `api.host` | Host address for API server |
| `gui.default_port` | Default port for GUI |
| `generated_code.default_directory` | Output directory for generated code |
| `sumo.absolute_sumo_dir` | Absolute path to ReSuMo directory |

**Note:** To change the GUI port, update both `config.json` and `GUI/vite.config.ts`.

---

## Project Structure

```
Studio/
├── API/                    # Django backend
│   ├── code_generation/    # Code generators (OCaml, Solidity)
│   ├── code_generators/    # Language-specific generators
│   ├── base_code/          # OCaml base templates
│   ├── objects/            # EDAM model classes
│   ├── process/            # Processing pipeline
│   ├── main.py             # API endpoints
│   └── requirements.txt
├── GUI/                    # React frontend
│   ├── src/
│   │   ├── components/
│   │   └── pages/
│   └── package.json
├── CLI/                    # Command-line interface
│   ├── cli.py              # Main CLI script
│   ├── cli_commands.py
│   ├── edam_file_parser.js
│   └── payload_generator.js
├── edams-models/           # Predefined EDAM models
├── ReSuMo/                 # ReSuMo analysis tool
├── Generated-code/         # Output directory
├── config.json
├── install.sh / install.bat
├── start_api.sh / start_api.bat
└── start_gui.sh / start_gui.bat
```

---

## Docker Deployment

### Quick Start

```bash
cd Docker
./run-docker.sh
```

Or with Docker Compose:

```bash
cd Docker
docker compose up --build
```

### Accessing Services

- **GUI**: http://localhost:3000
- **API**: http://localhost:5000

### CLI in Docker

```bash
docker exec -it edam-studio edam-cli assettransfer --mode 2
```

### Pushing Image

```bash
cd Docker
./push-image.sh -r docker.io -u yourusername -i edam-studio
```

---

## Troubleshooting

### Virtual Environment Issues

```bash
cd Studio
./install.sh
```

### Port Conflicts

```bash
./start_api.sh 9000
# Update GUI port in GUI/vite.config.ts and config.json
```

### opam Not Found

- **Linux/macOS**: Install from https://opam.ocaml.org/doc/Install.html
- **Windows**: Use WSL or Cygwin

### Missing Dependencies

```bash
# Python
pip install -r API/requirements.txt

# Node
cd GUI && npm install
cd ../ReSuMo && npm install
```

### Permission Issues (Linux/macOS)

```bash
chmod +x Studio/*.sh
chmod +x Studio/CLI/*.sh
```

---

## Additional Resources

- **Model definitions**: `Studio/edams-models/edam/models/`
- **API endpoints**: `Studio/API/main.py` and `Studio/API/urls.py`
- **Base code templates**: `Studio/API/base_code/`
- **CLI documentation**: `Studio/CLI/cli.py` and `Studio/CLI/cli_commands.py`
- **GUI components**: `Studio/GUI/src/components/`

---

## License

See [LICENSE](../LICENSE) file for details.

---

*This documentation was auto-generated. Last updated: 2025.*
