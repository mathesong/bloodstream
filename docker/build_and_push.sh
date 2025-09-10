#!/bin/bash

# Build Docker image from the root directory using the dockerfile in docker subdirectory
cd ..
docker build -f docker/dockerfile -t mathesong/bloodstream:latest . --platform linux/amd64
docker push mathesong/bloodstream:latest

