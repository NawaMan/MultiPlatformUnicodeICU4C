@echo off
setlocal

REM Check if clang is available
where clang >nul 2>nul
if errorlevel 1 (
    echo ERROR: clang not found in PATH.
    exit /b 1
)

REM Get clang version
for /f "tokens=2 delims= " %%v in ('clang --version ^| findstr /i "clang version"') do (
    set "CLANG_VERSION=%%v"
    goto :check_version
)

:check_version
echo Detected Clang version: %CLANG_VERSION%
echo %CLANG_VERSION% | findstr /b "20." >nul
if errorlevel 1 (
    echo ERROR: Clang version 20 is required.
    exit /b 1
)

echo Clang 20 is available and valid.

REM Your actual build command goes here
REM Example:
REM cmake -G "Ninja" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ .
REM ninja

endlocal
