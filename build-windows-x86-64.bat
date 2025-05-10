@echo off
setlocal

REM Check if clang is available
where clang >nul 2>nul
if errorlevel 1 (
    echo ERROR: clang not found in PATH.
    exit /b 1
)

REM Get clang version line
for /f "delims=" %%v in ('clang --version ^| findstr /i "clang version"') do (
    for /f "tokens=3" %%x in ("%%v") do (
        set "CLANG_VERSION=%%x"
    )
)

echo Detected Clang version: %CLANG_VERSION%
echo %CLANG_VERSION% | findstr /b "20." >nul
if errorlevel 1 (
    echo ERROR: Clang version 20 is required.
    exit /b 1
)

echo Clang 20 is available and valid.

REM Add your build logic here...

endlocal
