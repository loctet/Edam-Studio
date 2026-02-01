#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Load configuration
if [ -f "config.json" ]; then
    API_PORT=$(python3 -c "import json; f=open('config.json'); data=json.load(f); print(data['api']['default_port']); f.close()" 2>/dev/null || echo "8000")
    API_HOST=$(python3 -c "import json; f=open('config.json'); data=json.load(f); print(data['api']['host']); f.close()" 2>/dev/null || echo "127.0.0.1")
else
    API_PORT="8000"
    API_HOST="127.0.0.1"
fi

eval $(opam env)

# Allow user to override port via command line argument
if [ ! -z "$1" ]; then
    API_PORT="$1"
fi

echo "========================================="
echo "Starting EDAM API Server"
echo "========================================="
echo "Host: $API_HOST"
echo "Port: $API_PORT"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "ERROR: Virtual environment not found!"
    echo "Please run install.sh first to set up the environment."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Check if API directory exists
if [ ! -d "API" ]; then
    echo "ERROR: API directory not found!"
    deactivate
    exit 1
fi

# Change to API directory
cd API

# Check if Django is installed
python manage.py --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Django not found in virtual environment!"
    echo "Please run install.sh first to install dependencies."
    deactivate
    exit 1
fi

echo "Starting Django development server..."
python manage.py runserver $API_HOST:$API_PORT

# Deactivate virtual environment when script exits
deactivate
