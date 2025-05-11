# PowerShell equivalent of prepare-icu4c-source.sh

param(
    [string]$BuildDir = (Join-Path (Get-Location) "build")
)

# Set up build directory and log
$BUILD_LOG = Join-Path $BuildDir "build.log"

# Create build directory if it doesn't exist
if (-not (Test-Path -Path $BuildDir)) {
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
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

# Define ICU4C download function
function Get-Icu4c {
    param(
        [string]$ICU_VERSION,
        [string]$ICU4C_FILE
    )

    if (-not $ICU_VERSION) {
        Write-Host "ERROR: ICU_VERSION is not set!" -ForegroundColor Red
        exit 1
    }

    Write-Message "Ensure ICU source"
    if (-not (Test-Path -Path $ICU4C_FILE)) {
        # Replace dots with hyphens for release tag, and with underscores for filename
        $releaseTag = $ICU_VERSION -replace '\.', '-'
        $fileVersion = $ICU_VERSION -replace '\.', '_'
        $ICU_URL = "https://github.com/unicode-org/icu/releases/download/release-$releaseTag/icu4c-$fileVersion-src.tgz"
        
        Write-Message "Downloading ICU4C..."
        Invoke-WebRequest -Uri $ICU_URL -OutFile $ICU4C_FILE
    }
}

# Define ICU4C extraction function
function Expand-Icu4c {
    param(
        [string]$ICU4C_FILE,
        [string]$ICU4C_DIR
    )

    Write-Message "Extracting ICU to $ICU4C_DIR ..."
    
    # Remove directory if it exists and create a new one
    if (Test-Path -Path $ICU4C_DIR) {
        Remove-Item -Path $ICU4C_DIR -Recurse -Force
    }
    New-Item -Path $ICU4C_DIR -ItemType Directory -Force | Out-Null
    
    # Save current location
    $currentLocation = Get-Location
    
    # Change to the ICU4C_DIR
    Set-Location -Path $ICU4C_DIR
    
    # Use tar (Windows 10 1803+ has tar built-in)
    tar -xzf $ICU4C_FILE --strip-components=1
    
    # Return to original location
    Set-Location -Path $currentLocation
}

# Download and extract ICU4C
$icu4cSourceTgz = Join-Path $BuildDir "icu4c-source.tgz"
$icu4cSourceDir = Join-Path $BuildDir "icu4c-source"

# Call the PowerShell functions with the approved verbs
Get-Icu4c -ICU_VERSION $ICU_VERSION -ICU4C_FILE $icu4cSourceTgz
Expand-Icu4c -ICU4C_FILE $icu4cSourceTgz -ICU4C_DIR $icu4cSourceDir
