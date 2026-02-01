@echo off
setlocal enabledelayedexpansion

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

:: Load configuration
set GUI_PORT=3000
if exist "config.json" (
    for /f "tokens=*" %%i in ('python -c "import json; f=open('config.json'); data=json.load(f); print(data['gui']['default_port']); f.close()" 2^>nul') do set GUI_PORT=%%i
)

echo =========================================
echo Starting EDAM GUI
echo =========================================
echo Port: %GUI_PORT%
echo.

if not exist "GUI" (
    echo ERROR: GUI directory not found!
    pause
    exit /b 1
)

if not exist "GUI\node_modules" (
    echo WARNING: GUI dependencies not installed. Running npm install...
    cd GUI
    call npm install
    cd ..
)

cd GUI
echo Starting GUI server on port %GUI_PORT%...
call npm start
