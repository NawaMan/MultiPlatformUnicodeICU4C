# build-windows-x86-64.ps1

$ErrorActionPreference = "Stop"

$CLANG_VERSION = "20"
$DIST_DIR = "$PSScriptRoot\dist"
$PROJECT_DIR = $PSScriptRoot
$BUILD_DIR = "$PROJECT_DIR\build\build-windows-x86-64"
$SOURCE_DIR = "$BUILD_DIR\icu4c-source"
$TARGET_DIR = "$BUILD_DIR\icu4c-target"
$BUILD_LOG = "$BUILD_DIR\build.log"

New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
New-Item -ItemType File -Force -Path $BUILD_LOG | Out-Null

# Check clang version
$clangVersion = (& clang --version | Select-String "clang version").ToString()
$actualVersion = $clangVersion -replace "^.*clang version (\d+).*$", '$1'

Write-Output "Detected Clang version: $actualVersion"
if ($actualVersion -ne $CLANG_VERSION) {
    Write-Error "ERROR: Clang version $CLANG_VERSION.x required."
    exit 1
}

# Assume source fetch/prep is done
Write-Output "Configuring ICU..."
Push-Location "$SOURCE_DIR\source"
$env:CC = "clang"
$env:CXX = "clang++"

cmd /c "runConfigureICU Windows --prefix=$TARGET_DIR --enable-static --disable-samples --disable-tests --with-data-packaging=static" >> $BUILD_LOG

Write-Output "Building ICU..."
cmd /c "nmake" >> $BUILD_LOG

Write-Output "Installing ICU..."
cmd /c "nmake install" >> $BUILD_LOG
Pop-Location

# Packaging
$zipName = "$DIST_DIR\icu4c-windows-x86-64_clang-$CLANG_VERSION.zip"
New-Item -ItemType Directory -Force -Path $DIST_DIR | Out-Null

Copy-Item "$PROJECT_DIR\version.txt","$PROJECT_DIR\versions.env","$PROJECT_DIR\LICENSE","$PROJECT_DIR\README.md" -Destination $TARGET_DIR -Force

Compress-Archive -Path "$TARGET_DIR\*" -DestinationPath $zipName -Force
Write-Output "Packaged: $zipName"

if (Test-Path $zipName) {
    $size = (Get-Item $zipName).Length / 1MB
    Write-Output "Size: {0:N2} MB" -f $size
    exit 0
} else {
    Write-Error "Build failed — archive not created"
    exit 1
}
