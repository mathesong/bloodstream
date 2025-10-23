#!/bin/bash
# Build Docker image from the root directory using the dockerfile in docker subdirectory
cd ..

# Set version
VERSION="v0.2.0"

# Build with version tag
docker build -f docker/dockerfile -t mathesong/bloodstream:${VERSION} . --platform linux/amd64

# Tag as latest
docker tag mathesong/bloodstream:${VERSION} mathesong/bloodstream:latest

# Push both tags
docker push mathesong/bloodstream:${VERSION}
docker push mathesong/bloodstream:latest
