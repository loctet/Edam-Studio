@echo off
setlocal enabledelayedexpansion

echo =========================================
echo EDAM Installation Script
echo =========================================
echo.

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

:: Step 0: Install Npm in the root directory
echo [0/7] Installing Npm in the root directory...
if exist "node_modules" (
    echo [WARN] Npm already installed in the root directory, removing old one...
    rmdir /s /q node_modules
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to remove old node_modules directory
        pause
        exit /b 1
    )
)
call npm install
if !errorlevel! neq 0 (
    echo [ERROR] Failed to install npm packages
    pause
    exit /b 1
)
echo [OK] Npm installed in the root directory
echo.

:: Step 1: Install GUI dependencies
echo [1/7] Installing GUI dependencies...
if exist "GUI" (
    cd GUI
    echo Running npm install in GUI directory...
    call npm install
    cd ..
    echo [OK] GUI dependencies installed
) else (
    echo [WARN] GUI directory not found, skipping...
)
echo.

:: Step 2: Install ReSuMo dependencies
echo [2/7] Installing ReSuMo dependencies...
if exist "ReSuMo" (
    cd ReSuMo
    echo Running npm install in ReSuMo directory...
    call npm install
    cd ..
    echo [OK] ReSuMo dependencies installed
) else (
    echo [WARN] ReSuMo directory not found, skipping...
)
echo.

:: Step 3: Create Python virtual environment
echo [3/7] Creating Python virtual environment...
if exist "venv" (
    echo [WARN] Virtual environment already exists. Removing old one...
    rmdir /s /q venv
)
python -m venv venv
if !errorlevel! neq 0 (
    echo [ERROR] Failed to create virtual environment. Make sure Python is installed.
    pause
    exit /b 1
)
echo [OK] Python virtual environment created
echo.

:: Step 4: Install Python requirements
echo [4/7] Installing Python requirements...
if exist "API\requirements.txt" (
    call venv\Scripts\activate.bat
    python -m pip install --upgrade pip
    pip install -r API\requirements.txt
    call venv\Scripts\deactivate.bat
    echo [OK] Python requirements installed
) else (
    echo [WARN] API\requirements.txt not found, skipping...
)
echo.

:: Step 5: Check and install opam
echo [5/7] Checking opam installation...
where opam >nul 2>&1
if !errorlevel! neq 0 (
    echo [WARN] opam not found. Please install opam first:
    echo    Visit: https://opam.ocaml.org/doc/Install.html
    echo    For Windows, you may need to use WSL or install via Cygwin
    echo.
    pause
) else (
    echo [OK] opam found
)
echo.

:: Step 6: Install OCaml packages via opam
echo [6/7] Installing OCaml packages (ocamlfind, z3, ocamlopt)...
where opam >nul 2>&1
if !errorlevel! equ 0 (
    echo Initializing opam if needed...
    opam init --yes --disable-sandboxing >nul 2>&1
    
    echo Installing ocamlfind...
    opam install ocamlfind --yes
    
    echo Installing z3...
    opam install z3 --yes
    
    echo Installing ocamlopt (usually included with OCaml)...
    opam switch create default ocaml-base-compiler --yes >nul 2>&1
    opam install ocaml-base-compiler --yes
    
    echo [OK] OCaml packages installed
) else (
    echo [WARN] opam not available, skipping OCaml package installation
    echo        Note: On Windows, you may need to use WSL for opam
)
echo.

:: Step 7: Update config.json with ReSuMo absolute path
echo [7/7] Updating config.json with ReSuMo absolute path...
if exist "ReSuMo" (
    set "RESUMO_ABS_PATH=%SCRIPT_DIR%ReSuMo"
    set "CONFIG_PATH=%SCRIPT_DIR%config.json"
    python -c "import json; import os; config_path = r'%CONFIG_PATH%'; resumo_path = os.path.abspath(r'%RESUMO_ABS_PATH%').replace(chr(92), '/'); config = json.load(open(config_path)) if os.path.exists(config_path) else {'api': {'default_port': 8000, 'host': '127.0.0.1'}, 'gui': {'default_port': 3000}, 'generated_code': {'default_directory': 'Generated-code'}, 'sumo': {}}; config.setdefault('sumo', {})['absolute_sumo_dir'] = resumo_path; json.dump(config, open(config_path, 'w'), indent=2); print('Updated config.json with ReSuMo path: ' + resumo_path)"
    if !errorlevel! equ 0 (
        echo [OK] config.json updated with ReSuMo absolute path
    ) else (
        echo [WARN] Failed to update config.json
    )
) else (
    echo [WARN] ReSuMo directory not found, skipping config.json update...
)
echo.

echo =========================================
echo Installation completed successfully!
echo =========================================
echo.
echo Next steps:
echo   1. Start the API server: start_api.bat [port]
echo   2. Start the GUI: start_gui.bat
echo.
pause
