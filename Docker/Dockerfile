# Multi-stage Dockerfile for EDAM Studio
# Runs GUI, API, and exposes CLI

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    build-essential \
    git \
    pkg-config \
    libgmp-dev \
    libffi-dev \
    m4 \
    unzip \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x from NodeSource (required for Vite)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install opam and OCaml
RUN curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh | sh -s /usr/local/bin || true && \
    opam --version || (echo "Opam installation may have failed, but continuing..." && true)

# Set working directory
WORKDIR /app

# Copy the entire Studio directory
COPY Studio /app/Studio

# Set working directory to Studio
WORKDIR /app/Studio

# Initialize opam and install OCaml packages
# Note: opam installation may take time and can be optional for basic functionality
RUN if command -v opam >/dev/null 2>&1; then \
    opam init --yes --disable-sandboxing || true; \
    eval $(opam env) || true; \
    opam install ocamlfind z3 ocaml-base-compiler --yes || echo "OCaml packages installation completed with warnings"; \
    else \
    echo "Opam not available, skipping OCaml setup"; \
    fi

# Install root npm dependencies
RUN if [ -f "package.json" ]; then npm install; fi

# Install GUI dependencies
RUN if [ -d "GUI" ]; then \
    cd GUI && \
    npm install && \
    cd ..; \
    fi

# Create Python virtual environment and install dependencies
# Remove any existing venv first to avoid path conflicts
RUN rm -rf venv && \
    python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    if [ -f "API/requirements.txt" ]; then \
        pip install -r API/requirements.txt; \
    fi && \
    deactivate

# Update config.json with ReSuMo absolute path and Docker-friendly settings
RUN python3 << 'EOF'
import json
import os

config_path = "config.json"
if os.path.exists(config_path):
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    config['sumo']['absolute_sumo_dir'] = "/app/Studio/ReSuMo"
    # Set API host to 0.0.0.0 for Docker (allows external connections)
    if 'api' in config:
        config['api']['host'] = "0.0.0.0"
    
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
EOF

# Update Vite config to allow external connections (for Docker)
# Use sed for a simpler approach that works reliably in Docker
RUN if [ -f "GUI/vite.config.ts" ]; then \
    sed -i "s/host: 'localhost'/host: '0.0.0.0'/g" GUI/vite.config.ts || \
    sed -i "s/host: \"localhost\"/host: \"0.0.0.0\"/g" GUI/vite.config.ts || true; \
    fi

# Create entrypoint script
RUN cat > /app/entrypoint.sh << 'ENTRYPOINT_EOF'
#!/bin/bash
set -e

cd /app/Studio

# Activate opam environment (optional, continue if it fails)
if command -v opam >/dev/null 2>&1; then
    eval $(opam env) || true
fi

# Activate Python virtual environment
source venv/bin/activate

# Load configuration
if [ -f "config.json" ]; then
    API_PORT=$(python3 -c "import json; f=open('config.json'); data=json.load(f); print(data['api']['default_port']); f.close()" 2>/dev/null || echo "5000")
    API_HOST=$(python3 -c "import json; f=open('config.json'); data=json.load(f); print(data['api']['host']); f.close()" 2>/dev/null || echo "0.0.0.0")
    GUI_PORT=$(python3 -c "import json; f=open('config.json'); data=json.load(f); print(data['gui']['default_port']); f.close()" 2>/dev/null || echo "3000")
else
    API_PORT="5000"
    API_HOST="0.0.0.0"
    GUI_PORT="3000"
fi

# Start API in background
echo "Starting API server on $API_HOST:$API_PORT..."
cd API
python manage.py runserver $API_HOST:$API_PORT &
API_PID=$!
cd ..

# Start GUI in background
echo "Starting GUI server on port $GUI_PORT..."
cd GUI
# Vite will use the host from vite.config.ts (already set to 0.0.0.0)
npm start &
GUI_PID=$!
cd ..

# Function to handle shutdown
cleanup() {
    echo "Shutting down services..."
    kill $API_PID 2>/dev/null || true
    kill $GUI_PID 2>/dev/null || true
    wait
    exit 0
}

trap cleanup SIGTERM SIGINT

# Wait for both processes
echo "========================================="
echo "EDAM Studio is running!"
echo "========================================="
echo "API: http://127.0.0.1:$API_PORT"
echo "GUI: http://127.0.0.1:$GUI_PORT"
echo ""
echo "CLI is available via:"
echo "  docker exec -it <container> /app/Studio/CLI/cli.py <args>"
echo "  or"
echo "  docker exec -it <container> edam-cli <args>"
echo ""
echo "Press Ctrl+C to stop..."
wait
ENTRYPOINT_EOF

RUN chmod +x /app/entrypoint.sh

# Create CLI wrapper script in PATH
RUN cat > /usr/local/bin/edam-cli << 'CLI_EOF'
#!/bin/bash
cd /app/Studio
source venv/bin/activate
eval $(opam env) || true
python3 /app/Studio/CLI/cli.py "$@"
CLI_EOF

RUN chmod +x /usr/local/bin/edam-cli

# Expose ports
EXPOSE 3000 5000

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
