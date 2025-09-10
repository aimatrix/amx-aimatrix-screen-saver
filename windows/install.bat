@echo off
REM AIMatrix Screen Saver Installer for Windows
REM Installs the screen saver to Windows System directory

echo =========================================
echo     AIMatrix Screen Saver Installer     
echo =========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This installer must be run as Administrator.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Check if screen saver file exists
if not exist "AIMatrixScreenSaver.scr" (
    echo ERROR: AIMatrixScreenSaver.scr not found!
    echo Please build the screen saver first using build.bat
    pause
    exit /b 1
)

REM Get Windows directory
set WINDIR=%SystemRoot%
set SYSDIR=%WINDIR%\System32

echo Installing AIMatrix Screen Saver...
echo.

REM Copy screen saver to system directory
copy /Y "AIMatrixScreenSaver.scr" "%SYSDIR%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy screen saver to system directory.
    pause
    exit /b 1
)

echo Installation successful!
echo.
echo AIMatrix Screen Saver has been installed to:
echo   %SYSDIR%\AIMatrixScreenSaver.scr
echo.
echo To activate the screen saver:
echo   1. Right-click on Desktop
echo   2. Select "Personalize"
echo   3. Click "Lock screen" (left menu)
echo   4. Click "Screen saver settings" (bottom)
echo   5. Select "AIMatrixScreenSaver" from the list
echo   6. Click "Settings" to configure options
echo   7. Click "OK" to save
echo.
pause