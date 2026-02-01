@echo off
setlocal enabledelayedexpansion

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

:: Load configuration
set API_PORT=8000
set API_HOST=127.0.0.1
if exist "config.json" (
    for /f "tokens=*" %%i in ('python -c "import json; f=open('config.json'); data=json.load(f); print(data['api']['default_port']); f.close()" 2^>nul') do set API_PORT=%%i
    for /f "tokens=*" %%i in ('python -c "import json; f=open('config.json'); data=json.load(f); print(data['api']['host']); f.close()" 2^>nul') do set API_HOST=%%i
)

:: Load opam environment
for /f "tokens=*" %%i in ('opam env') do @%%i

:: Allow user to override port via command line argument
if not "%~1"=="" (
    set API_PORT=%~1
)

echo =========================================
echo Starting EDAM API Server
echo =========================================
echo Host: %API_HOST%
echo Port: %API_PORT%
echo.

:: Check if virtual environment exists
if not exist "venv" (
    echo ERROR: Virtual environment not found!
    echo Please run install.bat first to set up the environment.
    pause
    exit /b 1
)

:: Activate virtual environment
call venv\Scripts\activate.bat

:: Check if API directory exists
if not exist "API" (
    echo ERROR: API directory not found!
    call venv\Scripts\deactivate.bat
    pause
    exit /b 1
)

:: Change to API directory
cd API

:: Check if Django is installed
python manage.py --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Django not found in virtual environment!
    echo Please run install.bat first to install dependencies.
    call venv\Scripts\deactivate.bat
    pause
    exit /b 1
)

echo Starting Django development server...
python manage.py runserver %API_HOST%:%API_PORT%

:: Deactivate virtual environment when script exits
call venv\Scripts\deactivate.bat
