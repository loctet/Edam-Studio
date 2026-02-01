#!/bin/bash
set -e  # Exit on error

echo "========================================="
echo "EDAM Installation Script"
echo "========================================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Step 0: Install Npm in the root directory
echo -e "${BLUE}[0/7] Installing Npm in the root directory...${NC}"
if [ -d "node_modules" ]; then
    echo -e "${YELLOW}⚠ Npm already installed in the root directory, removing old one...${NC}"
    rm -rf node_modules
fi
npm install
echo -e "${GREEN}✓ Npm installed in the root directory${NC}"

# Step 1: Install GUI dependencies
echo -e "${BLUE}[1/7] Installing GUI dependencies...${NC}"
if [ -d "GUI" ]; then
    cd GUI
    echo "Running npm install in GUI directory..."
    npm install
    cd ..
    echo -e "${GREEN}✓ GUI dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠ GUI directory not found, skipping...${NC}"
fi

# Step 2: Install ReSuMo dependencies
echo -e "${BLUE}[2/7] Installing ReSuMo dependencies...${NC}"
if [ -d "ReSuMo" ]; then
    cd ReSuMo
    echo "Running npm install in ReSuMo directory..."
    npm install
    cd ..
    echo -e "${GREEN}✓ ReSuMo dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠ ReSuMo directory not found, skipping...${NC}"
fi

# Step 3: Create Python virtual environment
echo -e "${BLUE}[3/7] Creating Python virtual environment...${NC}"
if [ -d "venv" ]; then
    echo -e "${YELLOW}⚠ Virtual environment already exists. Removing old one...${NC}"
    rm -rf venv
fi
python3 -m venv venv
echo -e "${GREEN}✓ Python virtual environment created${NC}"

# Step 4: Install Python requirements
echo -e "${BLUE}[4/7] Installing Python requirements...${NC}"
if [ -f "API/requirements.txt" ]; then
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r API/requirements.txt
    deactivate
    echo -e "${GREEN}✓ Python requirements installed${NC}"
else
    echo -e "${YELLOW}⚠ API/requirements.txt not found, skipping...${NC}"
fi

# Step 5: Check and install opam
echo -e "${BLUE}[5/7] Checking opam installation...${NC}"
if ! command -v opam &> /dev/null; then
    echo -e "${YELLOW}⚠ opam not found. Please install opam first:${NC}"
    echo "   Visit: https://opam.ocaml.org/doc/Install.html"
    echo "   Or use: curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh | sh"
    read -p "Press Enter to continue after installing opam, or Ctrl+C to exit..."
else
    echo -e "${GREEN}✓ opam found${NC}"
fi

# Step 6: Install OCaml packages via opam
echo -e "${BLUE}[6/7] Installing OCaml packages (ocamlfind, z3, ocamlopt)...${NC}"
if command -v opam &> /dev/null; then
    echo "Initializing opam if needed..."
    opam init --yes --disable-sandboxing 2>/dev/null || true
    
    echo "Installing ocamlfind..."
    opam install ocamlfind --yes
    
    echo "Installing z3..."
    opam install z3 --yes
    
    echo "Installing ocamlopt (usually included with OCaml)..."
    opam switch create default ocaml-base-compiler --yes 2>/dev/null || true
    opam install ocaml-base-compiler --yes
    
    echo -e "${GREEN}✓ OCaml packages installed${NC}"
else
    echo -e "${YELLOW}⚠ opam not available, skipping OCaml package installation${NC}"
fi

# Step 7: Update config.json with ReSuMo absolute path
echo -e "${BLUE}[7/7] Updating config.json with ReSuMo absolute path...${NC}"
if [ -d "ReSuMo" ]; then
    RESUMO_ABS_PATH="$(cd "$SCRIPT_DIR/ReSuMo" && pwd)"
    if python3 << EOF
import json
import os
import sys

config_path = "$SCRIPT_DIR/config.json"
resumo_path = "$RESUMO_ABS_PATH"

if os.path.exists(config_path):
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    config['sumo']['absolute_sumo_dir'] = resumo_path
    
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Updated config.json with ReSuMo path: {resumo_path}")
    sys.exit(0)
else:
    print(f"Warning: config.json not found at {config_path}")
    sys.exit(1)
EOF
    then
        echo -e "${GREEN}✓ config.json updated with ReSuMo absolute path${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to update config.json${NC}"
    fi
else
    echo -e "${YELLOW}⚠ ReSuMo directory not found, skipping config.json update...${NC}"
fi

chmod +x start_gui.sh
chmod +x start_api.sh

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Start the API server: ./start_api.sh [port]"
echo "  2. Start the GUI: ./start_gui.sh"
echo ""
