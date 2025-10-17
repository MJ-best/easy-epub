@echo off
REM EasyPub Windows Build Script
REM Run this on a Windows machine with Flutter installed

echo =========================================
echo EasyPub Windows Build Script
echo =========================================
echo.

echo Step 1: Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo Step 2: Generating Hive adapters...
call flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo =========================================
echo Building for Windows...
echo =========================================
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Failed to build Windows application
    exit /b %ERRORLEVEL%
)

echo.
echo =========================================
echo Build Summary
echo =========================================
echo Build complete!
echo.
echo Output location:
echo   build\windows\x64\runner\Release\
echo.
echo To create an installer, use Inno Setup or NSIS
echo.
