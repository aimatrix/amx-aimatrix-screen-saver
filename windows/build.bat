@echo off
echo Building Matrix Screen Saver for Windows...

:: Set up Visual Studio environment (modify path as needed)
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat" 2>nul
if errorlevel 1 call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat" 2>nul

:: Compile resources
rc MatrixScreenSaver.rc
if errorlevel 1 goto error

:: Compile and link
cl /EHsc MatrixScreenSaver.cpp MatrixScreenSaver.res /link /subsystem:windows scrnsave.lib comctl32.lib user32.lib gdi32.lib kernel32.lib advapi32.lib /out:MatrixScreenSaver.scr

if errorlevel 1 goto error

echo Build successful! MatrixScreenSaver.scr created.
echo To install, right-click on MatrixScreenSaver.scr and select "Install"
echo or copy it to C:\Windows\System32\ directory.
goto end

:error
echo Build failed!

:end
pause