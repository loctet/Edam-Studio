#!/bin/bash
# Load Docker image from archive for artifact evaluation

set -e

ARCHIVE_FILE="edam-artifact.tar.gz"
IMAGE_NAME="edam-artifact"

if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "Error: Archive file $ARCHIVE_FILE not found!"
    echo "Please ensure the archive file is in the current directory."
    exit 1
fi

echo "========================================="
echo "Loading EDAM Artifact Docker Image"
echo "========================================="

echo "Loading image from $ARCHIVE_FILE..."
gunzip -c $ARCHIVE_FILE | docker load

echo ""
echo "========================================="
echo "Image loaded successfully!"
echo "========================================="
echo "Image name: $IMAGE_NAME"
echo ""
echo "To run the container:"
echo "  docker run -d -p 3000:3000 -p 5000:5000 --name edam-artifact $IMAGE_NAME"
echo ""
echo "Or use docker-compose:"
echo "  docker-compose up"
echo ""
