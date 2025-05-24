#!/bin/bash

# Define helper functions
print_section() {
    echo ""
    echo "===== $1 ====="
    echo ""
}


# Set environment variables
export CLANG_VERSION=$(cat versions.env | grep CLANG_VERSION | cut -d= -f2)

tool-version() {
    local cmd="$1"
    local pattern="${2:-version [0-9]\+}"

    if ! command -v "$cmd" &>/dev/null; then
        echo "not_installed"
        return
    fi

    local output version
    output=$("$cmd" --version 2>/dev/null)
    version=$(echo "$output" | grep -o "$pattern" | awk '{print $NF}')

    if [[ -z "$version" ]]; then
        echo "Warning: Unable to parse version for '$cmd'. Full output:"
        echo "$output"
        echo "not_installed"
    else
        echo "$version"
    fi
}


NEED_LLVM_INSTALL=false

[[ "$(tool-version clang       | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true
[[ "$(tool-version clang++     | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true
[[ "$(tool-version llvm-ar     | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true
[[ "$(tool-version llvm-ranlib | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true


if $NEED_LLVM_INSTALL; then
    # Install LLVM/Clang if needed
    echo "Installing LLVM/Clang version $CLANG_VERSION..."

    # Install LLVM/Clang
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh || true
    ./llvm.sh ${CLANG_VERSION}
    rm llvm.sh

    # Create symlinks for clang and LLVM tools to be available without version suffix
    update-alternatives --install /usr/bin/clang       clang       /usr/bin/clang-${CLANG_VERSION}       100 || true
    update-alternatives --install /usr/bin/clang++     clang++     /usr/bin/clang++-${CLANG_VERSION}     100 || true
    update-alternatives --install /usr/bin/llvm-ar     llvm-ar     /usr/bin/llvm-ar-${CLANG_VERSION}     100 || true
    update-alternatives --install /usr/bin/llvm-ranlib llvm-ranlib /usr/bin/llvm-ranlib-${CLANG_VERSION} 100 || true

    update-alternatives --set clang       /usr/bin/clang-${CLANG_VERSION}       || true
    update-alternatives --set clang++     /usr/bin/clang++-${CLANG_VERSION}     || true
    update-alternatives --set llvm-ar     /usr/bin/llvm-ar-${CLANG_VERSION}     || true
    update-alternatives --set llvm-ranlib /usr/bin/llvm-ranlib-${CLANG_VERSION} || true
fi


print_section "Compiler Information"

echo "which clang      : "$(which clang)
echo "which clang++    : "$(which clang++)
echo "which llvm-ar    : "$(which llvm-ar)
echo "which llvm-ranlib: "$(which llvm-ranlib)
echo ""

echo "Clang       version: "$(clang       --version | head -n 1)
echo "Clang++     version: "$(clang++     --version | head -n 1)
echo "LLVM-ar     version: "$(llvm-ar     --version | head -n 1)
echo "LLVM-ranlib version: "$(llvm-ranlib --version | head -n 1)

print_section "Build Environment Setup Complete"
echo "Your system is now ready for building."
