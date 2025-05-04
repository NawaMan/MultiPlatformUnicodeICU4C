#!/bin/bash

set -e

DIST_FILE=$1
if [ "$DIST_FILE" == "" ]; then
    echo "Usage: $0 <dist-file>"
    exit 1
fi

DIST_DIR=${DIST_FILE%/*}
BUILD_DIR=$(pwd)/build

rm    -Rf "$BUILD_DIR"
mkdir     "$BUILD_DIR"

cp    "$DIST_FILE"              "$BUILD_DIR"/icu4c.zip
unzip "$BUILD_DIR"/icu4c.zip -d "$BUILD_DIR"
echo ""

echo "Compiling..."
echo "BUILD_DIR: $BUILD_DIR"

clang++ \
    -std=c++23                    \
    -I"$BUILD_DIR"/include        \
    -L"$BUILD_DIR"/lib            \
    *.cpp                         \
    "$BUILD_DIR"/lib/libicuuc.a   \
    "$BUILD_DIR"/lib/libicui18n.a \
    "$BUILD_DIR"/lib/libicudata.a \
    -o simple-test

echo ""

echo "Running..."
./simple-test
echo ""

echo "Success!"
echo ""
