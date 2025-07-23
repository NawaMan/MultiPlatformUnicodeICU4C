#!/bin/bash

set -e

source ../sh-sources/common-source.sh

print_section "Installing dependencies"
apt-get update
apt-get install -y              \
                                \
                                \
    build-essential             \
    g++                         \
                                \
                                \
    libfmt-dev                  \
    lsb_release                 \
                                \
                                \
                                \
                                \
    unzip                       \
    wget

../ensure-linux-llvm-setup.sh
