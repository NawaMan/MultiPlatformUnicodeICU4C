#!/usr/bin/env pwsh
# PowerShell equivalent of build-linux-x86-64.sh

param(
    [string]$DIST_DIR = (Join-Path (Get-Location) "dist")
)

$ARCH = "x86"

# PowerShell equivalent of 'set -e' - stop on first error
$ErrorActionPreference = "Stop"

$PROJECT_DIR = Get-Location
$BUILD_DIR = Join-Path $PROJECT_DIR "build\build-windows-${ARCH}-64"
$SOURCE_DIR = Join-Path $BUILD_DIR "icu4c-source"
$TARGET_DIR = Join-Path $BUILD_DIR "icu4c-target"
$BUILD_LOG = Join-Path $BUILD_DIR "build.log"

# Create build directory if it doesn't exist
if (-not (Test-Path -Path $BUILD_DIR)) {
    New-Item -Path $BUILD_DIR -ItemType Directory -Force | Out-Null
}

# Create or clear log file
if (-not (Test-Path -Path $BUILD_LOG)) {
    New-Item -Path $BUILD_LOG -ItemType File -Force | Out-Null
} else {
    Clear-Content -Path $BUILD_LOG
}


# Define logging functions
function Write-Message {
    param([string]$Text)
    Write-Host $Text
    Add-Content -Path $BUILD_LOG -Value $Text
}

function Write-EmptyLine {
    Write-Host ""
    Add-Content -Path $BUILD_LOG -Value ""
}

function Write-Section {
    param([string]$Text)
    Write-Host "`n=== $Text ===`n" -ForegroundColor Yellow
    Add-Content -Path $BUILD_LOG -Value ""
    Add-Content -Path $BUILD_LOG -Value "=== $Text ==="
    Add-Content -Path $BUILD_LOG -Value ""
}

function Write-Status {
    param([string]$Text)
    Write-Host "$Text`n" -ForegroundColor Blue
    Add-Content -Path $BUILD_LOG -Value $Text
    Add-Content -Path $BUILD_LOG -Value ""
}

function Stop-WithError {
    param([string]$Text)
    Write-Host "ERROR: $Text" -ForegroundColor Red
    Add-Content -Path $BUILD_LOG -Value "ERROR: $Text"
    exit 1
}

# Source version information from versions.env
$versionsPath = Join-Path (Get-Location) "versions.env"
if (Test-Path -Path $versionsPath) {
    # Parse the versions.env file to extract variables
    $versionContent = Get-Content -Path $versionsPath
    foreach ($line in $versionContent) {
        if ($line -match '^\s*([^=\s]+)\s*=\s*(.*)$') {
            $varName = $matches[1]
            $varValue = $matches[2].Trim("'").Trim('"')
            Set-Variable -Name $varName -Value $varValue
        }
    }
}
Write-Status "Clang version: $ACTUAL_CLANG_VERSION"

# Check compiler versions
Write-Host "Clang       version: $(clang --version)"
Write-Host "Clang++     version: $(clang++ --version)"

# On Windows, LLVM tools might not have version suffixes
# Try to find LLVM tools with and without version suffixes
function Get-LLVMToolVersion {
    param(
        [string]$ToolName,
        [string]$Version
    )
    
    # First try with version suffix
    $versionedTool = "$ToolName-$Version"
    try {
        $output = & $versionedTool --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $output -join ' '
        }
    } catch {}
    
    # Then try without version suffix
    try {
        $output = & $ToolName --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $output -join ' '
        }
    } catch {}
    
    # Finally try in LLVM bin directory if it exists
    $llvmBinPath = "C:\Program Files\LLVM\bin"
    if (Test-Path "$llvmBinPath\$ToolName.exe") {
        try {
            $output = & "$llvmBinPath\$ToolName.exe" --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output -join ' '
            }
        } catch {}
    }
    
    return "Not found"
}

$llvmArVersion = Get-LLVMToolVersion -ToolName "llvm-ar" -Version $CLANG_VERSION
$llvmRanlibVersion = Get-LLVMToolVersion -ToolName "llvm-ranlib" -Version $CLANG_VERSION

Write-Host "LLVM-ar     version: $llvmArVersion"
Write-Host "LLVM-ranlib version: $llvmRanlibVersion"

Write-Section "Check compiler version"
$ACTUAL_CLANG_VERSION = (clang --version | Select-String -Pattern 'clang version ([0-9]+)' | ForEach-Object { $_.Matches.Groups[1].Value })
if ($BUILD_CLANG -eq "true" -and $IGNORE_COMPILER_VERSION -eq 0) {
    if ($ACTUAL_CLANG_VERSION.Split('.')[0] -ne $CLANG_VERSION) {
        Stop-WithError "Clang version $CLANG_VERSION.x required, found $ACTUAL_CLANG_VERSION."
    }
}
Write-Status "Clang version: $ACTUAL_CLANG_VERSION"

# Prepare ICU source
Write-Section "Prepare ICU source"
Write-Status "Running prepare-icu4c-source.ps1 script..."
try {
    $prepareOutput = & .\prepare-icu4c-source.ps1 -BuildDir $BUILD_DIR 2>&1
    Write-Status "Prepare script completed successfully"
    Add-Content -Path $BUILD_LOG -Value $prepareOutput
} catch {
    Write-Status "Error during source preparation: $_"
    Stop-WithError "Source preparation failed: $_"
}
Write-Status "Source: $SOURCE_DIR"

# Build Windows x86 64
Write-Section "Build Windows ${ARCH} 64"

# Set environment variables
$env:CC = "clang"
$env:CXX = "clang++"

# Set LLVM tool paths based on what we found earlier
function Get-LLVMToolPath {
    param(
        [string]$ToolName,
        [string]$Version
    )
    
    # First try with version suffix
    $versionedTool = "$ToolName-$Version"
    try {
        if (Get-Command $versionedTool -ErrorAction SilentlyContinue) {
            return $versionedTool
        }
    } catch {}
    
    # Then try without version suffix
    try {
        if (Get-Command $ToolName -ErrorAction SilentlyContinue) {
            return $ToolName
        }
    } catch {}
    
    # Finally try in LLVM bin directory if it exists
    $llvmBinPath = "C:\Program Files\LLVM\bin"
    if (Test-Path "$llvmBinPath\$ToolName.exe") {
        return "$llvmBinPath\$ToolName.exe"
    }
    
    return $null
}

$env:AR = Get-LLVMToolPath -ToolName "llvm-ar" -Version $CLANG_VERSION
$env:RANLIB = Get-LLVMToolPath -ToolName "llvm-ranlib" -Version $CLANG_VERSION

Write-Status "Using AR: $($env:AR)"
Write-Status "Using RANLIB: $($env:RANLIB)"

Write-Status "Configuring..."

# Change to source directory
Push-Location $SOURCE_DIR

# For Windows, we'll use the MSVC build files instead of the configure script
Write-Status "Using MSVC build approach for Windows"

# Check if we have the necessary MSVC build files
if (Test-Path -Path "./source/allinone/allinone.sln") {
    Write-Status "Found MSVC solution file"
} else {
    Write-Status "WARNING: MSVC solution file not found!"
    Get-ChildItem -Path "./source/allinone" | ForEach-Object { Write-Status "Found: $($_.Name)" }
    Stop-WithError "Cannot find MSVC build files"
}

# Locate MSBuild reliably using vswhere
Write-Status "Locating MSBuild using vswhere..."

$vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path -Path $vswherePath)) {
    Stop-WithError "vswhere.exe not found at $vswherePath. Please ensure Visual Studio Build Tools are installed."
}

$vsInstallPath = & "$vswherePath" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
if (-not $vsInstallPath) {
    Stop-WithError "Visual Studio installation with MSBuild not found."
}

$msbuildPath = Join-Path $vsInstallPath "MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path -Path $msbuildPath)) {
    Stop-WithError "MSBuild.exe not found at $msbuildPath"
}

Write-Status "Resolved MSBuild path: $msbuildPath"

# === ✅ FIX START: Remove UWP projects and patch for static lib build ===

# Remove UWP project references from the solution
Write-Status "Removing UWP projects from allinone.sln..."
$slnPath = "$SOURCE_DIR\source\allinone\allinone.sln"
(Get-Content $slnPath) | Where-Object { $_ -notmatch '_uwp\.vcxproj' } | Set-Content $slnPath

# Delete UWP project files
Write-Status "Removing UWP .vcxproj and filter files..."
Get-ChildItem -Path "$SOURCE_DIR\source" -Recurse -Include "*_uwp.vcxproj", "*_uwp.vcxproj.filters" | ForEach-Object {
    Write-Host "Removing: $($_.FullName)"
    Remove-Item $_.FullName -Force
}

# Patch ICU .vcxproj files to build static libs instead of DLLs
Write-Status "Patching ICU .vcxproj files for static build..."
$projFiles = Get-ChildItem -Path "$SOURCE_DIR\source\allinone" -Recurse -Filter *.vcxproj
foreach ($proj in $projFiles) {
    (Get-Content $proj.PSPath) -replace 'ConfigurationType>DynamicLibrary', 'ConfigurationType>StaticLibrary' |
        Set-Content $proj.PSPath
    (Get-Content $proj.PSPath) -replace 'RuntimeLibrary>MultiThreadedDLL', 'RuntimeLibrary>MultiThreaded' |
        Set-Content $proj.PSPath
    (Get-Content $proj.PSPath) -replace 'U_ICU_IMPLEMENTATION', 'U_STATIC_IMPLEMENTATION' |
        Set-Content $proj.PSPath
}


# Remove UWP project files to prevent build failure and DLL output
Write-Status "Removing UWP projects to avoid toolset errors and DLLs..."
Get-ChildItem -Path "$SOURCE_DIR\source" -Recurse -Include "*_uwp.vcxproj", "*_uwp.vcxproj.filters" |
    ForEach-Object {
        Write-Host "Removing: $($_.FullName)"
        Remove-Item $_.FullName -Force
    }


# Patch ICU projects for static build
$projFiles = Get-ChildItem -Path source/allinone -Recurse -Filter *.vcxproj
foreach ($proj in $projFiles) {
    (Get-Content $proj.PSPath) -replace 'ConfigurationType>DynamicLibrary', 'ConfigurationType>StaticLibrary' |
    Set-Content $proj.PSPath
    (Get-Content $proj.PSPath) -replace 'RuntimeLibrary>MultiThreadedDLL', 'RuntimeLibrary>MultiThreaded' |
    Set-Content $proj.PSPath
    (Get-Content $proj.PSPath) -replace 'U_ICU_IMPLEMENTATION', 'U_STATIC_IMPLEMENTATION' |
    Set-Content $proj.PSPath
}


# Get number of processors for parallel build
$numProcs = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
Write-Status "Using $numProcs processors for parallel build"

Write-Status "Building ICU using MSVC..."
try {
    # Navigate to the allinone directory
    Push-Location "./source/allinone"
    
    # Build the solution
    Write-Status "Running MSBuild..."
    $buildOutput = & $msbuildPath "allinone.sln" `
        "/p:Configuration=Release"        `
        "/p:Platform=x64"                 `
        "/p:RuntimeLibrary=MultiThreaded" `
        "/p:ICU_ENABLE_STATIC=1"          `
        "/maxcpucount:$numProcs"
    Write-Status "MSBuild completed"
    Add-Content -Path $BUILD_LOG -Value $buildOutput
    
    # Return to the source directory
    Pop-Location
    
    # Copy the built files to the target directory
    Write-Status "Installing (copying files to target directory)..."
    
    # Create target directories
    New-Item -Path "$TARGET_DIR\bin" -ItemType Directory -Force | Out-Null
    New-Item -Path "$TARGET_DIR\lib" -ItemType Directory -Force | Out-Null
    New-Item -Path "$TARGET_DIR\include" -ItemType Directory -Force | Out-Null
    
    # Copy binaries
    Copy-Item -Path "./bin64/*.dll" -Destination "$TARGET_DIR\bin" -Force
    Copy-Item -Path "./bin64/*.exe" -Destination "$TARGET_DIR\bin" -Force
    
    # Copy libraries
    Copy-Item -Path "./lib64/*.lib" -Destination "$TARGET_DIR\lib" -Force
    
    # Copy headers
    Copy-Item -Path "./include/*" -Destination "$TARGET_DIR\include" -Recurse -Force
    
    Write-Status "Installation completed"
} catch {
    Write-Status "Error during build/install: $_"
    Stop-WithError "Build failed: $_"
}
Write-EmptyLine

# Return to original directory
Pop-Location

# Packaging
Write-Section "Packaging..."

$BUILD_ZIP = Join-Path $DIST_DIR "icu4c-${ICU_VERSION}_windows-${ARCH}-64_clang-${CLANG_VERSION}.zip"

# Create dist directory if it doesn't exist
if (-not (Test-Path -Path $DIST_DIR)) {
    New-Item -Path $DIST_DIR -ItemType Directory -Force | Out-Null
}

# Copy files to target directory
Copy-Item -Path (Join-Path $PROJECT_DIR "version.txt") -Destination $TARGET_DIR
Copy-Item -Path (Join-Path $PROJECT_DIR "versions.env") -Destination $TARGET_DIR
Copy-Item -Path (Join-Path $PROJECT_DIR "LICENSE") -Destination $TARGET_DIR
Copy-Item -Path (Join-Path $PROJECT_DIR "README.md") -Destination $TARGET_DIR

# Create zip file using PowerShell's Compress-Archive instead of zip command
Write-Status "Creating ZIP archive..."
try {
    # If the zip file already exists, remove it
    if (Test-Path -Path $BUILD_ZIP) {
        Remove-Item -Path $BUILD_ZIP -Force
    }
    
    # Use Compress-Archive to create the zip file
    Compress-Archive -Path "$TARGET_DIR\*" -DestinationPath $BUILD_ZIP -CompressionLevel Optimal
    
    Write-Status "ZIP archive created successfully"
} catch {
    Write-Status "Error creating ZIP archive: $_"
    Stop-WithError "Failed to create ZIP archive: $_"
}

Write-Message "File: $BUILD_ZIP"

if (Test-Path -Path $BUILD_ZIP) {
    $fileSize = (Get-Item $BUILD_ZIP).Length / 1MB
    Write-Message "Size: $([math]::Round($fileSize, 2)) MB"
    
    # Set permissions (PowerShell equivalent of chmod 777)
    $acl = Get-Acl $BUILD_ZIP
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $BUILD_ZIP $acl
    
    Write-Status "Build succeeded!"
    Write-EmptyLine
    exit 0
} else {
    Write-Status "Build failed!"
    exit 1
}
