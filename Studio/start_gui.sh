#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Load configuration
if [ -f "config.json" ]; then
    GUI_PORT=$(python3 -c "import json; f=open('config.json'); data=json.load(f); print(data['gui']['default_port']); f.close()" 2>/dev/null || echo "3000")
else
    GUI_PORT="3000"
fi

echo "========================================="
echo "Starting EDAM GUI"
echo "========================================="
echo "Port: $GUI_PORT"
echo ""

if [ ! -d "GUI" ]; then
    echo "ERROR: GUI directory not found!"
    exit 1
fi

if [ ! -d "GUI/node_modules" ]; then
    echo "WARNING: GUI dependencies not installed. Running npm install..."
    cd GUI
    npm install
    cd ..
fi

cd GUI
echo "Starting GUI server on port $GUI_PORT..."
npm start
