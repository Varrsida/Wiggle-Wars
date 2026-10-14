@echo off
title WIGGLE WARS! — Master One-Click Launcher
echo =======================================================
echo    >>> WIGGLE WARS! WEBCAM GESTURE PARTY GAME <<<
echo =======================================================
echo.
echo 1. Starting Python Multi-Modal Tracker in background...
start "WIGGLE WARS Tracker" cmd /c "python \"%~dp0tracker\tracker.py\""
echo.
echo 2. Waiting 2 seconds for TCP socket servers to bind...
timeout /t 2 /nobreak >nul
echo.
echo 3. Launching Godot 4.7.2 Game Client...
"C:\Users\Varrsida\Downloads\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0."
echo.
pause
