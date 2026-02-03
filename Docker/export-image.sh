#!/bin/bash
# Export EDAM Studio Docker image to a compressed archive file
# This creates a tar.gz file that can be shared or loaded on another machine

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default values
SOURCE_IMAGE="edam-studio:latest"
OUTPUT_FILE="edam-studio.tar.gz"
BUILD_IF_MISSING=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Export EDAM Studio Docker image to a compressed archive file"
    echo ""
    echo "Options:"
    echo "  -i, --image IMAGE_NAME     Source image name (default: edam-studio:latest)"
    echo "  -o, --output OUTPUT_FILE   Output file name (default: edam-studio.tar.gz)"
    echo "  -b, --no-build             Don't build image if it doesn't exist"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Export default image"
    echo "  $0"
    echo ""
    echo "  # Export with custom name"
    echo "  $0 -o my-edam-image.tar.gz"
    echo ""
    echo "  # Export specific image"
    echo "  $0 -i my-custom-image:tag -o my-image.tar.gz"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            SOURCE_IMAGE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -b|--no-build)
            BUILD_IF_MISSING=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

cd "$SCRIPT_DIR"

# Check if source image exists
SOURCE_EXISTS=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -Fx "${SOURCE_IMAGE}" || echo "")

# Build the image if it doesn't exist
if [ -z "$SOURCE_EXISTS" ]; then
    if [ "$BUILD_IF_MISSING" = true ]; then
        echo -e "${YELLOW}Image '${SOURCE_IMAGE}' not found. Building...${NC}"
        docker build -f Dockerfile -t ${SOURCE_IMAGE} "$PROJECT_ROOT"
        echo -e "${GREEN}Build completed.${NC}"
    else
        echo -e "${RED}Error: Image '${SOURCE_IMAGE}' not found!${NC}"
        echo "Use -b flag to build it automatically, or build it first with:"
        echo "  docker build -f Docker/Dockerfile -t ${SOURCE_IMAGE} .."
        exit 1
    fi
else
    echo -e "${GREEN}Found image: ${SOURCE_IMAGE}${NC}"
    # Show image details
    echo -e "${YELLOW}Image details:${NC}"
    docker images "${SOURCE_IMAGE}" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}"
fi

echo ""
echo "========================================="
echo "Exporting Docker Image"
echo "========================================="
echo "Source image: $SOURCE_IMAGE"
echo "Output file: $OUTPUT_FILE"
echo ""

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}Warning: Output file '$OUTPUT_FILE' already exists.${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Export cancelled."
        exit 1
    fi
    rm -f "$OUTPUT_FILE"
fi

# Export the image
echo -e "${YELLOW}Exporting image to $OUTPUT_FILE...${NC}"
docker save ${SOURCE_IMAGE} | gzip > "$OUTPUT_FILE"

# Check if export was successful
if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Export completed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Output file: $OUTPUT_FILE"
    echo "File size: $FILE_SIZE"
    echo ""
    echo "To load this image on another machine:"
    echo "  gunzip -c $OUTPUT_FILE | docker load"
    echo ""
    echo "Or use the load script:"
    echo "  cp $OUTPUT_FILE <target-machine>/Docker/"
    echo "  cd <target-machine>/Docker"
    echo "  ./load-docker.sh"
    echo ""
else
    echo -e "${RED}Error: Failed to create output file!${NC}"
    exit 1
fi
