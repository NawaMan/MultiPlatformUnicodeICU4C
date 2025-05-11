param (
    [string]$BuildDir = "$PSScriptRoot\build\build-windows-x86-64",
    [string]$ICUVersion = "74.2"
)

$SourceTar = "$BuildDir\icu4c-source.tgz"
$SourceDir = "$BuildDir\icu4c-source"
$LogFile = "$BuildDir\build.log"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType File -Force -Path $LogFile | Out-Null

Write-Output "📥 Downloading ICU4C version $ICUVersion..."

if (!(Test-Path $SourceTar)) {
    $icuUrl = "https://github.com/unicode-org/icu/releases/download/release-$($ICUVersion -replace '\.', '-')/icu4c-$($ICUVersion -replace '\.', '_')-src.tgz"
    Invoke-WebRequest -Uri $icuUrl -OutFile $SourceTar
}

Write-Output "📦 Extracting ICU..."
if (Test-Path $SourceDir) {
    Remove-Item -Recurse -Force $SourceDir
}
New-Item -ItemType Directory -Path $SourceDir | Out-Null

# 1st stage: extract .tgz -> .tar
& 7z e $SourceTar -o"$BuildDir" -y
# 2nd stage: extract .tar -> actual files
$tarPath = "$BuildDir\icu4c-source.tar"
& 7z x $tarPath -o"$SourceDir" -y
Remove-Item $tarPath

# Strip one folder level if needed (similar to --strip-components=1)
$innerFolder = Get-ChildItem "$SourceDir" | Where-Object { $_.PSIsContainer } | Select-Object -First 1
if ($innerFolder) {
    Move-Item "$innerFolder\*" "$SourceDir"
    Remove-Item "$innerFolder" -Recurse
}

Write-Output "✅ ICU source prepared at $SourceDir"
