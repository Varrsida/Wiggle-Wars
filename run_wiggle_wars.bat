@echo off
setlocal
title WIGGLE WARS! - Master Game Launcher
echo =======================================================
echo    *** WIGGLE WARS! WEBCAM GESTURE PARTY GAME ***
echo =======================================================
echo.

set "GODOT_BIN=C:\Users\Varrsida\Downloads\Godot_v4.7.2-stable_win64_console.exe"
set "TRACKER_SCRIPT=%~dp0tracker\tracker.py"

:: 1. Validate Godot executable
if not exist "%GODOT_BIN%" (
    echo [ERROR] Godot executable was not found at:
    echo   "%GODOT_BIN%"
    echo Please ensure Godot 4.7.2 is installed at that location.
    echo.
    pause
    exit /b 1
)

:: 2. Validate Python
where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python was not found in your system PATH!
    echo Please install Python 3.10+ and add it to PATH.
    echo.
    pause
    exit /b 1
)

:: 3. Validate tracker script exists
if not exist "%TRACKER_SCRIPT%" (
    echo [ERROR] Tracker script not found at:
    echo   "%TRACKER_SCRIPT%"
    echo.
    pause
    exit /b 1
)

:: 4. Check if tracker is already running on port 9998
echo Checking webcam tracker status...
python -c "import socket, sys; s=socket.socket(); s.settimeout(0.3); res=s.connect_ex(('127.0.0.1', 9998)); s.close(); sys.exit(0 if res==0 else 1)" >nul 2>nul
if errorlevel 1 (
    echo [1/3] Starting Python webcam tracker in background...
    start "WIGGLE WARS Tracker" cmd /c "python \"%TRACKER_SCRIPT%\""
    echo [2/3] Waiting for webcam and socket servers to initialize...
    ping -n 4 127.0.0.1 >nul 2>nul
) else (
    echo [INFO] Webcam tracker is already active on port 9998. Reusing running process.
)

:: 5. Check if Godot is already running
powershell -NoProfile -Command "if (Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }" >nul 2>nul
if errorlevel 1 (
    echo [NOTICE] An instance of Godot is already open!
    echo Bringing existing game window to front or starting second instance...
)

:: 6. Launch Godot Game
echo [3/3] Launching Godot 4.7.2 game client...
echo.
"%GODOT_BIN%" --path "%~dp0." %*
set "GAME_EXIT_CODE=%errorlevel%"

echo.
echo =======================================================
echo    WIGGLE WARS session ended (code %GAME_EXIT_CODE%).
echo =======================================================
echo.

:: Clean up background tracker when game closes
echo Closing background webcam tracker...
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name = ''python.exe''' | Where-Object { $_.CommandLine -like '*tracker.py*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>nul
echo Tracker closed successfully.

endlocal
