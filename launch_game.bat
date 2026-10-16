@echo off
setlocal
title WIGGLE WARS! - Game Launcher
echo =======================================================
echo    *** WIGGLE WARS! WEBCAM GESTURE PARTY GAME ***
echo =======================================================
echo.
echo Launching Godot 4.7.2 Wiggle Wars...
echo.

set "GODOT_BIN=C:\Users\Varrsida\Downloads\Godot_v4.7.2-stable_win64_console.exe"

if not exist "%GODOT_BIN%" (
    echo [ERROR] Godot executable was not found at:
    echo "%GODOT_BIN%"
    echo Please ensure Godot 4.7.2 is installed in your Downloads folder.
    echo.
    pause
    exit /b 1
)

"%GODOT_BIN%" --path "%~dp0" %*
if errorlevel 1 (
    echo.
    echo [NOTICE] Godot closed with exit code %errorlevel%.
)

endlocal
