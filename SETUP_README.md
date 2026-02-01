# EDAM Setup and Installation Guide

This guide explains how to install and run the EDAM project components.

## Configuration File

The `config.json` file contains global settings for the project:

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

You can modify these values to customize your setup:
- `api.default_port`: Default port for the API server (can be overridden when starting)
- `api.host`: Host address for the API server
- `gui.default_port`: Default port for the GUI (note: also check `GUI/vite.config.ts`)
- `generated_code.default_directory`: Default directory where generated code will be saved

## Installation

### Windows
Run the installation script:
```cmd
install.bat
```

### Linux/macOS
Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

The installation script will:
1. Install GUI dependencies (runs `npm install` in the `GUI` directory)
2. Create a Python virtual environment in the root directory
3. Install Python requirements from `API/requirements.txt`
4. Check for opam installation (OCaml package manager)
5. Install OCaml packages: `ocamlfind`, `z3`, and `ocamlopt` via opam

**Note:** On Windows, opam may require WSL (Windows Subsystem for Linux) or Cygwin for installation.

## Starting the Services

### Start the API Server

#### Windows
```cmd
start_api.bat [port]
```

#### Linux/macOS
```bash
chmod +x start_api.sh
./start_api.sh [port]
```

The API server will start on the default port from `config.json` (8000) unless you specify a different port:
```bash
./start_api.sh 9000  # Starts on port 9000
```

### Start the GUI

#### Windows
```cmd
start_gui.bat
```

#### Linux/macOS
```bash
chmod +x start_gui.sh
./start_gui.sh
```

The GUI will start using Vite. The port is configured in `GUI/vite.config.ts` (default: 3000).

**Note:** To change the GUI port, you need to update both `config.json` and `GUI/vite.config.ts`.

## Project Structure

```
.
├── config.json          # Global configuration file
├── install.sh           # Installation script (Linux/macOS)
├── install.bat          # Installation script (Windows)
├── start_api.sh         # Start API script (Linux/macOS)
├── start_api.bat        # Start API script (Windows)
├── start_gui.sh         # Start GUI script (Linux/macOS)
├── start_gui.bat        # Start GUI script (Windows)
├── venv/                # Python virtual environment (created during installation)
├── API/                 # Django API backend
├── GUI/                 # React frontend
├── Generated-code/      # Default directory for generated code
└── ...
```

## Troubleshooting

### Virtual environment not found
Run the installation script again: `install.sh` or `install.bat`

### Port already in use
Either:
- Specify a different port: `./start_api.sh 9000`
- Or update `config.json` with a different default port

### opam not found
- **Linux/macOS**: Install opam from https://opam.ocaml.org/doc/Install.html
- **Windows**: Consider using WSL (Windows Subsystem for Linux) for opam installation

### GUI port conflicts
Update the port in `GUI/vite.config.ts`:
```typescript
server: {
  port: 3000, // Change this to your desired port
}
```

## Development Workflow

1. Run installation once: `./install.sh` (or `install.bat` on Windows)
2. Start API in one terminal: `./start_api.sh`
3. Start GUI in another terminal: `./start_gui.sh`
4. Access:
   - GUI: http://localhost:3000
   - API: http://localhost:8000 (or your configured port)
