#!/bin/bash

set -e

BASE_DIR=$(pwd)
PROJECT_DIR=$(pwd)/../..
DIST_DIR="$BASE_DIR/dist"

docker build -t icu4c-linux-x86-64 .
docker run -it --rm -v "$PROJECT_DIR":/app icu4c-linux-x86-64
