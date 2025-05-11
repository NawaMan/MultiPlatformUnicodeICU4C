#!/usr/bin/env pwsh
# PowerShell equivalent of clean.sh

# Remove build directories
if (Test-Path -Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

if (Test-Path -Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
}

if (Test-Path -Path "tests/build") {
    Remove-Item -Path "tests/build" -Recurse -Force
}

if (Test-Path -Path "tests/simple-test") {
    Remove-Item -Path "tests/simple-test" -Recurse -Force
}

Write-Host "Cleanup complete!" -ForegroundColor Green
