@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0optimize_brave.ps1"
set "result=%ERRORLEVEL%"
echo.
set /p "close=Pressione Enter para fechar..."
exit /b %result%

