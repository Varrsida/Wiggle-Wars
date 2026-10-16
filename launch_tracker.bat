@echo off
setlocal
title WIGGLE WARS! - Multi-Modal Gesture Tracker
echo =======================================================
echo    *** WIGGLE WARS! MULTI-MODAL WEBCAM TRACKER ***
echo =======================================================
echo.
echo Starting MediaPipe Face, Hand, and Pose Tracker...
echo Streaming telemetry on TCP 9999 and video on TCP 9998...
echo Real Speech Recognition and TTS bridge enabled...
echo.

where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python was not found in your system PATH!
    echo Please install Python 3.10+ and add it to PATH.
    echo.
    pause
    exit /b 1
)

python "%~dp0tracker\tracker.py" --preview
if errorlevel 1 (
    echo.
    echo [NOTICE] Tracker stopped with exit code %errorlevel%.
)

endlocal
