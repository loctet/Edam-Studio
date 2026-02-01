#!/bin/bash
# Build script for EDAM Studio Docker image

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "========================================="
echo "Building EDAM Studio Docker Image"
echo "========================================="
echo "Project root: $PROJECT_ROOT"
echo ""

cd "$SCRIPT_DIR"

# Build the image
docker build -f Dockerfile -t edam-studio:latest "$PROJECT_ROOT"

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo ""
echo "To run the container:"
echo "  docker run -d -p 3000:3000 -p 5000:5000 --name edam-studio edam-studio:latest"
echo ""
echo "Or use docker compose:"
echo "  cd Docker && docker compose up"
echo ""
echo "Note: Use 'docker compose' (v2) instead of 'docker-compose' (v1)"
echo ""
