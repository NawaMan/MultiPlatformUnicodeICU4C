# Source common functions if available
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$ScriptPath\ps-sources\Common-Source.ps1") {
    . "$ScriptPath\ps-sources\Common-Source.ps1"
}

function Write-Section($title) {
    Write-Host "`n===== $title =====`n"
}

Write-Section "Checking build dependencies"

# Check for CMake
try {
    $cmakeVersion = (cmake --version | Select-Object -First 1).ToString()
    Write-Host "CMake: $cmakeVersion"
} catch {
    Write-Host "CMake not found. Installing..."
    # Install CMake using winget
    winget install -e --id Kitware.CMake --accept-source-agreements --accept-package-agreements
}

# Check for Visual Studio Build Tools
$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio"
if (Test-Path $vsPath) {
    Write-Host "Visual Studio found at: $vsPath"
} else {
    Write-Host "Visual Studio Build Tools not found. GitHub runners should have this pre-installed."
    Write-Host "If running locally, install Visual Studio Build Tools from https://visualstudio.microsoft.com/downloads/"
}

# Ensure 7-Zip is available (for zip/unzip operations)
try {
    $7zipPath = (Get-Command 7z -ErrorAction SilentlyContinue).Source
    if ($7zipPath) {
        Write-Host "7-Zip found at: $7zipPath"
    } else {
        Write-Host "7-Zip not found. Installing..."
        # Install 7-Zip using winget
        winget install -e --id 7zip.7zip --accept-source-agreements --accept-package-agreements
    }
} catch {
    Write-Host "7-Zip not found. Installing..."
    # Install 7-Zip using winget
    winget install -e --id 7zip.7zip --accept-source-agreements --accept-package-agreements
}

# Ensure Ninja is available (for building)
try {
    $ninjaPath = (Get-Command ninja -ErrorAction SilentlyContinue).Source
    if ($ninjaPath) {
        Write-Host "Ninja found at: $ninjaPath"
    } else {
        Write-Host "Ninja not found. Installing..."
        # Install Ninja using winget
        winget install -e --id Ninja.Ninja --accept-source-agreements --accept-package-agreements
    }
} catch {
    Write-Host "Ninja not found. Installing..."
    # Install Ninja using winget
    winget install -e --id Ninja.Ninja --accept-source-agreements --accept-package-agreements
}

$vsInstallPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
& "$vsInstallPath\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64 > $null

# Now run the LLVM setup script
Write-Section "Setting up LLVM/Clang"
& "$ScriptPath\Ensure-WindowsLlvmSetup.ps1"

Write-Section "Build Environment Setup Complete"
Write-Host "Your Windows system is now ready for building."
