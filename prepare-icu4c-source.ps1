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

# 1st: extract .tgz → .tar
& 7z e $SourceTar -o"$BuildDir" -y
$tarFile = "$BuildDir\icu4c-source.tar"

# 2nd: extract .tar into $SourceDir
& 7z x $tarFile -o"$SourceDir" -y
Remove-Item $tarFile

Write-Output "✅ Extracted ICU to $SourceDir"
