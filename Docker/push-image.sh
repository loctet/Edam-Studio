#!/bin/bash
# Push EDAM Studio Docker image to a container registry
# Supports: Docker Hub, GitHub Container Registry (ghcr.io), and custom registries

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default values
REGISTRY=""
USERNAME=""
IMAGE_NAME="edam-studio"
TAG="latest"
VERSION=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Push EDAM Studio Docker image to a container registry"
    echo ""
    echo "Options:"
    echo "  -r, --registry REGISTRY    Registry URL (e.g., docker.io, ghcr.io, or custom)"
    echo "  -u, --username USERNAME    Username for the registry"
    echo "  -i, --image IMAGE_NAME     Image name (default: edam-studio)"
    echo "  -t, --tag TAG              Tag for the image (default: latest)"
    echo "  -v, --version VERSION      Version tag (creates both 'latest' and version tags)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Push to Docker Hub"
    echo "  $0 -r docker.io -u yourusername -i edam-studio"
    echo ""
    echo "  # Push to GitHub Container Registry"
    echo "  $0 -r ghcr.io -u yourusername -i edam-studio"
    echo ""
    echo "  # Push with version tag"
    echo "  $0 -r docker.io -u yourusername -i edam-studio -v 1.0.0"
    echo ""
    echo "  # Push to custom registry"
    echo "  $0 -r registry.example.com -u yourusername -i edam-studio"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
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

# Validate required parameters
if [ -z "$REGISTRY" ] || [ -z "$USERNAME" ]; then
    echo -e "${RED}Error: Registry and username are required${NC}"
    echo ""
    usage
fi

cd "$SCRIPT_DIR"

# Build the image first if it doesn't exist
if ! docker images | grep -q "^${IMAGE_NAME}"; then
    echo -e "${YELLOW}Image not found locally. Building...${NC}"
    docker build -f Dockerfile -t ${IMAGE_NAME}:${TAG} "$PROJECT_ROOT"
fi

# Construct full image name
if [ "$REGISTRY" = "docker.io" ]; then
    # Docker Hub format: username/imagename:tag
    FULL_IMAGE_NAME="${USERNAME}/${IMAGE_NAME}:${TAG}"
else
    # Other registries format: registry/username/imagename:tag
    FULL_IMAGE_NAME="${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${TAG}"
fi

echo "========================================="
echo "Pushing EDAM Studio Docker Image"
echo "========================================="
echo "Registry: $REGISTRY"
echo "Username: $USERNAME"
echo "Image: $IMAGE_NAME"
echo "Tag: $TAG"
echo "Full name: $FULL_IMAGE_NAME"
echo ""

# Tag the image
echo -e "${YELLOW}Tagging image...${NC}"
docker tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE_NAME}

# If version is provided, also tag with version
if [ -n "$VERSION" ]; then
    VERSION_IMAGE_NAME="${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${VERSION}"
    echo -e "${YELLOW}Tagging with version: ${VERSION}...${NC}"
    docker tag ${IMAGE_NAME}:${TAG} ${VERSION_IMAGE_NAME}
fi

# Login to registry if needed
echo -e "${YELLOW}Logging in to registry...${NC}"
if [ "$REGISTRY" = "docker.io" ]; then
    echo "Please enter your Docker Hub password:"
    docker login -u "$USERNAME"
elif [ "$REGISTRY" = "ghcr.io" ]; then
    echo "For GitHub Container Registry, use a Personal Access Token (PAT) as password."
    echo "Create one at: https://github.com/settings/tokens"
    echo "Required scopes: write:packages"
    docker login ghcr.io -u "$USERNAME"
else
    echo "Please enter your registry password:"
    docker login "$REGISTRY" -u "$USERNAME"
fi

# Push the image
echo ""
echo -e "${YELLOW}Pushing image...${NC}"
docker push ${FULL_IMAGE_NAME}

# Push version tag if provided
if [ -n "$VERSION" ]; then
    echo -e "${YELLOW}Pushing version tag...${NC}"
    docker push ${VERSION_IMAGE_NAME}
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Push completed successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Image is now available at:"
echo "  ${FULL_IMAGE_NAME}"
if [ -n "$VERSION" ]; then
    echo "  ${VERSION_IMAGE_NAME}"
fi
echo ""
echo "To pull and run the image:"
echo "  docker pull ${FULL_IMAGE_NAME}"
echo "  docker run -d -p 3000:3000 -p 5000:5000 --name edam-studio ${FULL_IMAGE_NAME}"
echo ""
