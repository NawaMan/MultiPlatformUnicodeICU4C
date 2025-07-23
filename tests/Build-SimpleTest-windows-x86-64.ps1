#!/usr/bin/env pwsh

# Get the distribution file from command line argument
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$DIST_FILE
)

# PowerShell equivalent of set -e - stop on first error
$ErrorActionPreference = "Stop"

# Extract the directory from the file path
$DIST_DIR = Split-Path -Parent $DIST_FILE
$BUILD_DIR = Join-Path (Get-Location) "build"

# Clean and recreate build directory
if (Test-Path -Path $BUILD_DIR) {
    Remove-Item -Path $BUILD_DIR -Recurse -Force
}
New-Item -Path $BUILD_DIR -ItemType Directory -Force | Out-Null

# Copy and extract the distribution file
Write-Host "Extracting ICU distribution..."
Copy-Item -Path $DIST_FILE -Destination (Join-Path $BUILD_DIR "icu4c.zip")
Expand-Archive -Path (Join-Path $BUILD_DIR "icu4c.zip") -DestinationPath $BUILD_DIR

Get-ChildItem -Recurse | Tree
Write-Output ""

# Find include and lib directories
$includeDir = Join-Path $BUILD_DIR "include"
$libDir = Join-Path $BUILD_DIR "lib"

Write-Host "Include directory: $includeDir"
Write-Host "Library directory: $libDir"

# List available library files
Write-Host "Available libraries:"
$availableLibs = Get-ChildItem -Path $libDir -Filter "*.lib" | Select-Object -ExpandProperty Name
foreach ($lib in $availableLibs) {
    Write-Host "  - $lib"
}

# Check for CPP files
$cppFiles = Get-ChildItem -Path "." -Filter "*.cpp"
if ($cppFiles.Count -eq 0) {
    Write-Host "ERROR: No .cpp files found in the current directory" -ForegroundColor Red
    exit 1
}

Write-Host "Found source files:"
foreach ($file in $cppFiles) {
    Write-Host "  - $($file.Name)"
}

# Simple compilation command
Write-Host "\nCompiling..." -ForegroundColor Cyan

# Create the command line
$cmd = "clang++ -std=c++23"
$cmd += " -I`"$includeDir`""
$cmd += " -L`"$libDir`""

# Add source files
foreach ($file in $cppFiles) {
    $cmd += " `"$($file.FullName)`""
}

# Add libraries - use the ones we found
$cmd += " `"$libDir\icuuc.lib`""
if ($availableLibs -contains "icuin.lib") {
    $cmd += " `"$libDir\icuin.lib`""
}
if ($availableLibs -contains "icudt.lib") {
    $cmd += " `"$libDir\icudt.lib`""
}
if ($availableLibs -contains "icuio.lib") {
    $cmd += " `"$libDir\icuio.lib`""
}

# On Windows, we don't include the fmt library as it's Linux-specific
# If fmt is needed, you would need to install it separately on Windows
# and specify the correct path to the Windows version of the library

# Output file
$cmd += " -o simple-test.exe"

# Show the command
Write-Host "Running: $cmd" -ForegroundColor Cyan

# Execute the command
try {
    # Use cmd.exe to run the command to avoid PowerShell escaping issues
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "`nCompilation successful!" -ForegroundColor Green
        
        if (Test-Path -Path ".\simple-test.exe") {
            Write-Host "Test is ready to run: .\simple-test.exe" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Compilation reported success but executable was not created" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nCompilation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "`nError executing compilation command: $_" -ForegroundColor Red
}
