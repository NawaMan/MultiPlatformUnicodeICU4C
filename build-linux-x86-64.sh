#!/bin/bash

set -e

DIST_DIR=${1:-$(pwd)/dist}

PROJECT_DIR=$(pwd)
BUILD_DIR=$(pwd)/build/build-linux64
SOURCE_DIR="$BUILD_DIR/icu4c-source"
TARGET_DIR="$BUILD_DIR/icu4c-target"
BUILD_LOG=$BUILD_DIR/build.log


mkdir -p "$BUILD_DIR"
touch    "$BUILD_LOG"

source versions.env
source sh-sources/common-source.sh



print_section "Check compiler version"
ACTUAL_CLANG_VERSION=$(clang --version | grep -o 'clang version [0-9]\+' | awk '{print $3}')
if [[ $BUILD_CLANG == "true" && $IGNORE_COMPILER_VERSION -eq 0 ]]; then
  if [[ "${ACTUAL_CLANG_VERSION%%.*}" != "$CLANG_VERSION" ]]; then
    exit_with_error "Clang version $CLANG_VERSION.x required, found $ACTUAL_CLANG_VERSION."
  fi
fi
print_status "Clang version: $ACTUAL_CLANG_VERSION"



print_section "Prepare ICU source"

./prepare-icu4c-source.sh "$BUILD_DIR"
print_status "Source: $SOURCE_DIR"


print_section "Build Linux 64"

export CC=clang
export CXX=clang++

print_status "Configuring..."

cd $SOURCE_DIR
./source/runConfigureICU    \
    Linux                   \
    --prefix="$TARGET_DIR"  \
    --enable-static         \
    --disable-extras        \
    --disable-samples       \
    --disable-shared        \
    --disable-tests         \
    --with-data-packaging=static \
    >> $BUILD_LOG
println

print_status "Building..."
make -j$(nproc) >> $BUILD_LOG
println

print_status "Installing..."
make install    >> $BUILD_LOG
println

print_section "Packaging..."

BUILD_ZIP="$DIST_DIR/icu4c-${ICU_VERSION}_linux-x86-64_clang-${CLANG_VERSION}.zip"
mkdir -p "$DIST_DIR"

cp "$PROJECT_DIR/version.txt"  "$TARGET_DIR"
cp "$PROJECT_DIR/versions.env" "$TARGET_DIR"
cp "$PROJECT_DIR/LICENSE"      "$TARGET_DIR"
cp "$PROJECT_DIR/README.md"    "$TARGET_DIR"

cd "$TARGET_DIR"
zip -r $BUILD_ZIP . >> $BUILD_LOG
print "File: $BUILD_ZIP"

if [ -f "$BUILD_ZIP" ]; then
    print "Size: $(du -h $BUILD_ZIP | cut -f1)"
    print_status "Build succeeded!"
    println
else
    print_status "Build failed!"
    exit 1
fi

