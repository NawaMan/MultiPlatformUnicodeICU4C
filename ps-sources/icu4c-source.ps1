# SOURCE ME - DO NOT RUN (Use dot-sourcing: . .\icu4c-source.ps1)

# This file is meant to be dot-sourced, common-source.ps1 should be sourced by the calling script

function Get-Icu4c {
    param(
        [string]$ICU_VERSION,
        [string]$ICU4C_FILE
    )

    if (-not $ICU_VERSION) {
        Stop-WithError "ICU_VERSION is not set!"
    }

    Write-Message "Ensure ICU source"
    if (-not (Test-Path -Path $ICU4C_FILE)) {
        # Replace dots with hyphens for release tag, and with underscores for filename
        $releaseTag = $ICU_VERSION -replace '\.', '-'
        $fileVersion = $ICU_VERSION -replace '\.', '_'
        $ICU_URL = "https://github.com/unicode-org/icu/releases/download/release-$releaseTag/icu4c-$fileVersion-src.tgz"
        
        Write-Message "📥 Downloading ICU4C..."
        Invoke-WebRequest -Uri $ICU_URL -OutFile $ICU4C_FILE
        Write-EmptyLine
    }
}

function Expand-Icu4c {
    param(
        [string]$ICU4C_FILE,
        [string]$ICU4C_DIR
    )

    Write-Message "📦 Extracting ICU to $ICU4C_DIR ..."
    
    # Remove directory if it exists and create a new one
    if (Test-Path -Path $ICU4C_DIR) {
        Remove-Item -Path $ICU4C_DIR -Recurse -Force
    }
    New-Item -Path $ICU4C_DIR -ItemType Directory -Force | Out-Null
    
    # Save current location
    $currentLocation = Get-Location
    
    # Change to the ICU4C_DIR
    Set-Location -Path $ICU4C_DIR
    
    # Extract the archive with --strip-components=1 equivalent
    # PowerShell doesn't have a direct equivalent, so we'll extract and then move files
    
    # Use 7-Zip if available, otherwise try tar (available in newer Windows versions)
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        # Extract using 7-Zip
        7z x $ICU4C_FILE -so | 7z x -aoa -si -ttar
        
        # Get the top-level directory name
        $topDir = Get-ChildItem -Directory | Select-Object -First 1
        
        # Move all contents from the top directory to current directory
        if ($topDir) {
            Get-ChildItem -Path $topDir.FullName | Move-Item -Destination .
            Remove-Item -Path $topDir.FullName -Recurse -Force
        }
    } else {
        # Try using tar (Windows 10 1803+ has tar built-in)
        tar -xzf $ICU4C_FILE --strip-components=1
    }
    
    # Return to original location
    Set-Location -Path $currentLocation
    
    Write-Host "END: Expand-Icu4c"
    Get-Location
    Get-ChildItem -Force
}
