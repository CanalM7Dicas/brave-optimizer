@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0optimize_brave.ps1"
set "result=%ERRORLEVEL%"
echo.
pause
exit /b %result%
