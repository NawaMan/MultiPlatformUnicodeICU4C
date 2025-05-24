# Ensure-WindowsLlvmSetup.ps1

# Load environment file
$envFile = "versions.env"
if (!(Test-Path $envFile)) {
    Write-Error "Cannot find versions.env"
    exit 1
}

# Parse CLANG_VERSION from file
$ClangMajor = Get-Content $envFile |
    Where-Object { $_ -match "^CLANG_VERSION=(\d+)" } |
    ForEach-Object { ($_ -split "=")[1] }

if (-not $ClangMajor) {
    Write-Error "CLANG_VERSION not defined in versions.env"
    exit 1
}

Write-Host "Requested LLVM major version: $ClangMajor"

# Check if clang++ is already installed with the correct major version
$existingClang = $null
try {
    $existingClang = Get-Command clang++ -ErrorAction SilentlyContinue
    if ($existingClang) {
        $versionOutput = & clang++ --version 2>$null
        if ($versionOutput -match "clang version (\d+)") {
            $installedMajor = $Matches[1]
            if ($installedMajor -eq $ClangMajor) {
                Write-Host "Found existing clang++ with major version $installedMajor (matches required version $ClangMajor)" -ForegroundColor Green
                
                # Skip to the compiler information section
                Print-Section "Compiler Information"
                
                Write-Host "clang path      : " -NoNewline
                Write-Host (Get-Command clang -ErrorAction SilentlyContinue).Source
                Write-Host "clang++ path    : " -NoNewline
                Write-Host (Get-Command clang++ -ErrorAction SilentlyContinue).Source
                Write-Host "llvm-ar path    : " -NoNewline
                Write-Host (Get-Command llvm-ar -ErrorAction SilentlyContinue).Source
                Write-Host "llvm-ranlib path: " -NoNewline
                Write-Host (Get-Command llvm-ranlib -ErrorAction SilentlyContinue).Source
                Write-Host ""
                
                Write-Host "Clang       version: " -NoNewline
                Write-Host (clang --version | Select-Object -First 1)
                Write-Host "Clang++     version: " -NoNewline
                Write-Host (clang++ --version | Select-Object -First 1)
                Write-Host "LLVM-ar     version: " -NoNewline
                Write-Host (llvm-ar --version | Select-Object -First 1)
                Write-Host "LLVM-ranlib version: " -NoNewline
                Write-Host (llvm-ranlib --version | Select-Object -First 1)
                
                Print-Section "Build Environment Setup Complete"
                Write-Host "Your system is now ready for building."
                exit 0
            } else {
                Write-Host "Found existing clang++ with major version $installedMajor (does not match required version $ClangMajor)" -ForegroundColor Yellow
            }
        }
    }
} catch {
    # Continue with installation if any error occurs during version check
    Write-Host "No suitable existing clang++ installation found" -ForegroundColor Yellow
}

# Fetch all LLVM releases from GitHub API
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/llvm/llvm-project/releases" `
                              -Headers @{ "User-Agent" = "PowerShell" }

# Filter to latest full release for the desired major version
$latest = $releases |
    Where-Object { $_.tag_name -match "^llvmorg-$ClangMajor\.\d+\.\d+$" } |
    Sort-Object { [version]($_.tag_name -replace '^llvmorg-', '') } -Descending |
    Select-Object -First 1

if (-not $latest) {
    Write-Error "No LLVM $ClangMajor.x.x release found on GitHub"
    exit 1
}

$ClangLatestVersion = $latest.tag_name -replace "llvmorg-", ""
$DownloadUrl = "https://github.com/llvm/llvm-project/releases/download/llvmorg-$ClangLatestVersion/LLVM-$ClangLatestVersion-win64.exe"
$InstallerPath = "$env:TEMP\LLVM-$ClangLatestVersion-win64.exe"

Write-Host "Resolved LLVM version: $ClangLatestVersion"

Write-Host "Download URL: $DownloadUrl"

# Download using curl
curl.exe -L -o $InstallerPath $DownloadUrl

if (!(Test-Path $InstallerPath)) {
    Write-Error "Download failed: $InstallerPath not found."
    exit 1
}

# Install
Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait

# PATH update
$llvmBin = "C:\Program Files\LLVM\bin"
$env:PATH = "$llvmBin;$env:PATH"

if ($env:GITHUB_PATH) {
    "$llvmBin" | Out-File -Append -Encoding utf8 $env:GITHUB_PATH
}

# Helper for section headers
function Print-Section($title) {
    Write-Host "`n===== $title =====`n"
}

Print-Section "Compiler Information"

Write-Host "clang path      : " -NoNewline
Write-Host (Get-Command clang -ErrorAction SilentlyContinue).Source
Write-Host "clang++ path    : " -NoNewline
Write-Host (Get-Command clang++ -ErrorAction SilentlyContinue).Source
Write-Host "llvm-ar path    : " -NoNewline
Write-Host (Get-Command llvm-ar -ErrorAction SilentlyContinue).Source
Write-Host "llvm-ranlib path: " -NoNewline
Write-Host (Get-Command llvm-ranlib -ErrorAction SilentlyContinue).Source
Write-Host "llvm-readobj path: " -NoNewline
Write-Host (Get-Command llvm-readobj -ErrorAction SilentlyContinue).Source
Write-Host ""

Write-Host "Clang       version: " -NoNewline
Write-Host (clang --version | Select-Object -First 1)
Write-Host "Clang++     version: " -NoNewline
Write-Host (clang++ --version | Select-Object -First 1)
Write-Host "LLVM-ar     version: " -NoNewline
Write-Host (llvm-ar --version | Select-Object -Skip 1 -First 1)
Write-Host "LLVM-ranlib version: " -NoNewline
Write-Host (llvm-ranlib --version | Select-Object -Skip 1 -First 1)

Print-Section "Build Environment Setup Complete"
Write-Host "Your system is now ready for building."
