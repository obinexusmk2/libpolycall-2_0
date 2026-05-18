#!/bin/bash
# LibPolyCall v2 - Docker Hub Publishing Script
# Author: OBINexus Computing
# Repository: obinexus/libpolycall

set -e

REGISTRY="docker.io"
NAMESPACE="obinexus"
IMAGE_NAME="libpolycall"
VERSION="2.0.0"
DOCKER_HUB_USER="${DOCKER_HUB_USER:-}"
DOCKER_HUB_TOKEN="${DOCKER_HUB_TOKEN:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== LibPolyCall v2 Docker Hub Publisher ===${NC}\n"

# Step 1: Build images
echo -e "${YELLOW}Step 1: Building Docker images...${NC}"
docker build -t ${NAMESPACE}/${IMAGE_NAME}:${VERSION} \
             -t ${NAMESPACE}/${IMAGE_NAME}:latest \
             --target runtime \
             .

# Verify build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful${NC}\n"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Step 2: Verify image
echo -e "${YELLOW}Step 2: Verifying image...${NC}"
docker run --rm ${NAMESPACE}/${IMAGE_NAME}:${VERSION} ls -lh /opt/polycall/lib/libpolycall* || true
echo ""

# Step 3: Login to Docker Hub
if [ -z "${DOCKER_HUB_TOKEN}" ]; then
    echo -e "${YELLOW}Step 3: Logging in to Docker Hub...${NC}"
    docker login -u "${DOCKER_HUB_USER}"
    echo ""
else
    echo -e "${YELLOW}Step 3: Using provided Docker Hub credentials...${NC}"
    echo "${DOCKER_HUB_TOKEN}" | docker login -u "${DOCKER_HUB_USER}" --password-stdin
    echo ""
fi

# Step 4: Push images
echo -e "${YELLOW}Step 4: Pushing images to Docker Hub...${NC}"
docker push ${NAMESPACE}/${IMAGE_NAME}:${VERSION}
docker push ${NAMESPACE}/${IMAGE_NAME}:latest

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Push successful${NC}\n"
else
    echo -e "${RED}✗ Push failed${NC}"
    exit 1
fi

# Step 5: Display push info
echo -e "${GREEN}=== Publishing Complete ===${NC}\n"
echo "Image pushed to Docker Hub:"
echo "  ${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${VERSION}"
echo "  ${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:latest"
echo ""
echo "Pull commands:"
echo "  docker pull ${NAMESPACE}/${IMAGE_NAME}:${VERSION}"
echo "  docker pull ${NAMESPACE}/${IMAGE_NAME}:latest"
echo ""
echo "Run command:"
echo "  docker run -it ${NAMESPACE}/${IMAGE_NAME}:latest"
