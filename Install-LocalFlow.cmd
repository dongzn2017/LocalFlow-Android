@echo off
setlocal
title LocalFlow Android USB Installer

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LocalFlow.ps1" %*
set "LOCALFLOW_EXIT=%ERRORLEVEL%"

echo.
if not "%LOCALFLOW_EXIT%"=="0" (
    echo LocalFlow installation did not complete.
) else (
    echo LocalFlow installer finished successfully.
)
echo.
pause
exit /b %LOCALFLOW_EXIT%
