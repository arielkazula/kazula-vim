#!/usr/bin/env bash
# @file ide_build.sh
# @brief Build (or rebuild) the Docker image.
set -e
IMAGE="nvim-ide:latest"
docker build -t "$IMAGE" "$(dirname "$0")" "$@"
echo "Image built: $IMAGE"
