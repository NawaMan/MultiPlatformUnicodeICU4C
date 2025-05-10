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
mkdir -p  "$BUILD_DIR"

cp    "$DIST_FILE"              "$BUILD_DIR"/icu4c.zip
unzip "$BUILD_DIR"/icu4c.zip -d "$BUILD_DIR"
echo ""

echo "Compiling..."
echo "BUILD_DIR: $BUILD_DIR"

clang++                           \
    -std=c++23                    \
    -stdlib=libstdc++             \
    -I"$BUILD_DIR/include"        \
    -L"$BUILD_DIR/lib"            \
    *.cpp                         \
    -Wl,--start-group             \
    "$BUILD_DIR/lib/libicui18n.a" \
    "$BUILD_DIR/lib/libicuuc.a"   \
    "$BUILD_DIR/lib/libicudata.a" \
    "$BUILD_DIR/lib/libicuio.a"   \
    -Wl,--end-group               \
    -lfmt                         \
    -o simple-test

echo ""
echo "Success!"
echo ""

echo "Test are ready to run: ./simple-test"
echo ""
