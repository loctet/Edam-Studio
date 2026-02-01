# EDAM Studio - Setup and Installation Guide

This guide provides detailed instructions for installing, configuring, and running EDAM Studio components.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Installation](#installation)
  - [Automated Installation](#automated-installation)
  - [Manual Installation](#manual-installation)
- [Starting the Services](#starting-the-services)
  - [API Server](#api-server)
  - [GUI Application](#gui-application)
- [Verification](#verification)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before installation, ensure you have the following installed:

- **Python 3.10+** with pip
- **Node.js** (v16 or higher) and npm
- **OCaml** and **opam** (OCaml package manager)
- **Z3** solver (installed via opam)

### Platform-Specific Notes

- **Linux/macOS**: Full support for all features
- **Windows**: opam may require WSL (Windows Subsystem for Linux) or Cygwin

## Configuration

### Configuration File

The `Studio/config.json` file contains global settings for the project:

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

You can modify these values to customize your setup:

| Option | Description | Default |
|--------|-------------|---------|
| `api.default_port` | Default port for the API server (can be overridden when starting) | 5000 |
| `api.host` | Host address for the API server | 127.0.0.1 |
| `gui.default_port` | Default port for the GUI (also check `GUI/vite.config.ts`) | 3000 |
| `generated_code.default_directory` | Directory where generated code will be saved | Generated-code |
| `sumo.absolute_sumo_dir` | Absolute path to ReSuMo directory | Auto-configured during installation |

**Note**: To change the GUI port, you need to update both `config.json` and `GUI/vite.config.ts`.

## Installation

### Automated Installation

The installation script automates the entire setup process.

#### Linux/macOS

```bash
cd Studio
chmod +x install.sh
./install.sh
```

#### Windows

```cmd
cd Studio
install.bat
```

### What the Installation Script Does

The installation script performs the following steps:

1. **Installs root-level npm dependencies**
   - Installs TypeScript and ts-node for model processing

2. **Installs GUI dependencies**
   - Runs `npm install` in the `GUI/` directory
   - Installs React, Vite, and all frontend dependencies

3. **Installs ReSuMo dependencies**
   - Runs `npm install` in the `ReSuMo/` directory
   - Sets up the analysis tool dependencies

4. **Creates Python virtual environment**
   - Creates `venv/` directory in the Studio folder
   - Sets up isolated Python environment

5. **Installs Python requirements**
   - Upgrades pip to latest version
   - Installs Django and all dependencies from `API/requirements.txt`

6. **Checks and installs opam**
   - Verifies opam installation
   - Provides instructions if opam is not found

7. **Installs OCaml packages**
   - Initializes opam if needed
   - Installs `ocamlfind`, `z3`, and `ocaml-base-compiler` via opam

8. **Updates configuration**
   - Updates `config.json` with ReSuMo absolute path
   - Makes startup scripts executable (Linux/macOS)

### Manual Installation

If you prefer manual installation or need to troubleshoot:

#### Step 1: Install Root Dependencies

```bash
cd Studio
npm install
```

#### Step 2: Install GUI Dependencies

```bash
cd GUI
npm install
cd ..
```

#### Step 3: Install ReSuMo Dependencies

```bash
cd ReSuMo
npm install
cd ..
```

#### Step 4: Create Python Virtual Environment

```bash
# Linux/macOS
python3 -m venv venv
source venv/bin/activate

# Windows
python -m venv venv
venv\Scripts\activate
```

#### Step 5: Install Python Requirements

```bash
pip install --upgrade pip
pip install -r API/requirements.txt
```

#### Step 6: Install OCaml Packages

```bash
# Initialize opam
opam init --yes --disable-sandboxing

# Install required packages
opam install ocamlfind z3 ocaml-base-compiler --yes

# Set up opam environment
eval $(opam env)  # Linux/macOS
# For Windows with WSL, use the same command in WSL
```

#### Step 7: Update Configuration

The ReSuMo path in `config.json` should be automatically updated during installation. If needed, manually update:

```json
{
  "sumo": {
    "absolute_sumo_dir": "/absolute/path/to/Studio/ReSuMo"
  }
}
```

## Starting the Services

### API Server

The API server provides the backend code generation engine.

#### Linux/macOS

```bash
cd Studio
chmod +x start_api.sh  # Only needed once
./start_api.sh [port]
```

#### Windows

```cmd
cd Studio
start_api.bat [port]
```

**Examples:**
```bash
# Use default port from config.json (5000)
./start_api.sh

# Use custom port
./start_api.sh 9000
```

**What it does:**
- Loads configuration from `config.json`
- Activates Python virtual environment
- Sets up opam environment
- Starts Django development server
- Default port: 5000 (configurable)

**Access:** http://localhost:5000 (or your configured port)

### GUI Application

The GUI provides the interactive web interface for model editing and code generation.

#### Linux/macOS

```bash
cd Studio
chmod +x start_gui.sh  # Only needed once
./start_gui.sh
```

#### Windows

```cmd
cd Studio
start_gui.bat
```

**What it does:**
- Loads configuration from `config.json`
- Checks for GUI dependencies (installs if missing)
- Starts Vite development server
- Default port: 3000

**Access:** http://localhost:3000

**Note:** The GUI port is also configured in `GUI/vite.config.ts`. To change the port, update both files.

## Verification

After installation and starting services, verify everything is working:

### 1. Check API Server

```bash
# Test API endpoint
curl http://localhost:5000/api/convert-bulk
# Should return an error (expected - needs POST with data)
```

### 2. Check GUI

- Open browser: http://localhost:3000
- You should see the EDAM Studio interface

### 3. Check CLI

```bash
cd Studio
source venv/bin/activate  # Linux/macOS
# or: venv\Scripts\activate  # Windows

python3 CLI/cli.py --help
# Should display CLI help message
```

### 4. Verify Dependencies

```bash
# Check Python packages
source venv/bin/activate
pip list | grep -i django

# Check OCaml packages
opam list | grep -E "ocamlfind|z3"

# Check Node packages
cd GUI && npm list --depth=0
```

## Project Structure

```
Studio/
├── config.json          # Global configuration file
├── install.sh           # Installation script (Linux/macOS)
├── install.bat          # Installation script (Windows)
├── start_api.sh         # Start API script (Linux/macOS)
├── start_api.bat        # Start API script (Windows)
├── start_gui.sh         # Start GUI script (Linux/macOS)
├── start_gui.bat        # Start GUI script (Windows)
├── venv/                # Python virtual environment (created during installation)
├── node_modules/        # Root-level Node.js dependencies
├── API/                 # Django API backend
│   ├── requirements.txt # Python dependencies
│   ├── manage.py        # Django management script
│   └── ...
├── GUI/                 # React frontend
│   ├── package.json     # Node.js dependencies
│   ├── vite.config.ts   # Vite configuration (includes port settings)
│   └── ...
├── CLI/                 # Command-line interface
│   ├── cli.py           # Main CLI script
│   └── ...
├── ReSuMo/              # ReSuMo analysis tool
│   └── ...
├── edams-models/        # Predefined EDAM models
│   └── ...
└── Generated-code/      # Default directory for generated code
```

## Development Workflow

### Standard Workflow

1. **Initial Setup** (one-time):
   ```bash
   cd Studio
   ./install.sh  # or install.bat on Windows
   ```

2. **Start Services** (each session):
   ```bash
   # Terminal 1: Start API server
   cd Studio
   ./start_api.sh
   
   # Terminal 2: Start GUI
   cd Studio
   ./start_gui.sh
   ```

3. **Access Services**:
   - GUI: http://localhost:3000
   - API: http://localhost:5000

4. **Development**:
   - Edit models via GUI or CLI
   - Generate code through interface
   - Check generated code in `Generated-code/` directory

### Quick Test

After installation, test the setup:

```bash
cd Studio
source venv/bin/activate  # Linux/macOS
# or: venv\Scripts\activate  # Windows

# Generate code for a simple model
python3 CLI/cli.py assettransfer --mode 2

# Check output
ls Generated-code/
```

## Troubleshooting

### Virtual Environment Not Found

**Symptoms:** Error when starting API server about missing venv

**Solution:**
```bash
cd Studio
./install.sh  # or install.bat on Windows
```

### Port Already in Use

**Symptoms:** Error message about port being in use

**Solutions:**

1. **Use a different port:**
   ```bash
   ./start_api.sh 9000  # Use port 9000 instead
   ```

2. **Update default port in config.json:**
   ```json
   {
     "api": {
       "default_port": 9000
     }
   }
   ```

3. **Find and stop the process using the port:**
   ```bash
   # Linux/macOS
   lsof -ti:5000 | xargs kill -9
   
   # Windows
   netstat -ano | findstr :5000
   taskkill /PID <PID> /F
   ```

### opam Not Found

**Symptoms:** Warning during installation about opam not being available

**Solutions:**

- **Linux/macOS:**
  ```bash
  # Install opam
  curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh | sh
  
  # Or use package manager
  # Ubuntu/Debian:
  sudo apt-get install opam
  # macOS:
  brew install opam
  ```

- **Windows:**
  - Use WSL (Windows Subsystem for Linux)
  - Or install via Cygwin
  - Follow Linux installation instructions in WSL

### GUI Port Conflicts

**Symptoms:** GUI fails to start or port 3000 is in use

**Solutions:**

1. **Update `GUI/vite.config.ts`:**
   ```typescript
   export default defineConfig({
     server: {
       port: 3001, // Change to available port
     },
   })
   ```

2. **Update `config.json`:**
   ```json
   {
     "gui": {
       "default_port": 3001
     }
   }
   ```

### Missing Dependencies

**Symptoms:** Import errors or missing modules

**Solutions:**

```bash
# Reinstall Python packages
cd Studio
source venv/bin/activate
pip install --upgrade pip
pip install -r API/requirements.txt

# Reinstall GUI dependencies
cd GUI
rm -rf node_modules  # Linux/macOS
# or: rmdir /s /q node_modules  # Windows
npm install

# Reinstall ReSuMo dependencies
cd ../ReSuMo
rm -rf node_modules
npm install
```

### OCaml Environment Issues

**Symptoms:** Errors related to OCaml or Z3

**Solutions:**

```bash
# Reinitialize opam environment
eval $(opam env)

# Reinstall OCaml packages
opam install ocamlfind z3 ocaml-base-compiler --yes

# Verify installation
opam list | grep -E "ocamlfind|z3"
```

### Permission Issues (Linux/macOS)

**Symptoms:** "Permission denied" when running scripts

**Solutions:**

```bash
# Make scripts executable
chmod +x Studio/*.sh
chmod +x Studio/CLI/*.sh

# Or run with explicit interpreter
bash Studio/install.sh
```

### Django Not Found

**Symptoms:** Error when starting API server about Django

**Solutions:**

```bash
cd Studio
source venv/bin/activate
pip install -r API/requirements.txt

# Verify Django installation
python -c "import django; print(django.get_version())"
```

### Node Modules Issues

**Symptoms:** Errors about missing Node.js packages

**Solutions:**

```bash
# Clean and reinstall
cd Studio/GUI
rm -rf node_modules package-lock.json
npm install

# Or for root dependencies
cd Studio
rm -rf node_modules package-lock.json
npm install
```

## Additional Resources

- **Main README**: See `README.md` for comprehensive project documentation
- **API Documentation**: See `Studio/API/main.py` for API endpoints
- **CLI Documentation**: See `Studio/CLI/cli.py` for CLI usage
- **Configuration**: See `Studio/config.json` for all configuration options

## Getting Help

If you encounter issues not covered in this guide:

1. Check the main `README.md` for additional troubleshooting
2. Verify all prerequisites are installed correctly
3. Ensure you're using the correct Python and Node.js versions
4. Check that all paths in `config.json` are correct
5. Review error messages carefully for specific guidance
