@echo off
cd /d "%~dp0"

:: Check if the bat is being run as admin
net session >nul 2>&1
if not %errorlevel% == 0 (
    echo Please run this script as Administrator.
    pause
	exit
)

if "%steam-artwork-manager_DEBUG%" == "1" (
    setx steam-artwork-manager_DEBUG 0 /m >nul
    echo Disabled debugging. Run this script again to enable it.
) else (
    setx steam-artwork-manager_DEBUG 1 /m >nul
    echo Enabled debugging. Run this script again to disable it.
)

pause