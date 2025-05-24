# SOURCE ME - DO NOT RUN (Use dot-sourcing: . .\Common-Source.ps1)

# Check if BUILD_LOG is set
if ([string]::IsNullOrEmpty($BUILD_LOG)) {
  Write-Host "BUILD_LOG is not set!"
  
  New-Item -Path "build"           -ItemType Directory -Force | Out-Null
  New-Item -Path "build/build.log" -ItemType File      -Force | Out-Null
  $script:BUILD_LOG = "build/build.log"
  Write-Host "Build log: $BUILD_LOG"
}

# == PRINTING FUNCTIONS ==

# PowerShell doesn't need color variables like bash
# We'll use the -ForegroundColor parameter instead

function Write-Message {
    param([Parameter(ValueFromRemainingArguments=$true)]$Text)
    $message = $Text -join " "
    Write-Host $message
    Add-Content -Path $BUILD_LOG -Value $message
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
