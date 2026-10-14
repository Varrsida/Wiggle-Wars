@echo off
title WIGGLE WARS! — Multi-Modal Gesture Tracker & Speech Bridge
echo =======================================================
echo    >>> WIGGLE WARS! MULTI-MODAL WEBCAM TRACKER <<<
echo =======================================================
echo.
echo Starting MediaPipe Face, Hand, and Pose Tracker...
echo Streaming telemetry on TCP 9999 and video on TCP 9998...
echo Real Speech Recognition and TTS bridge enabled...
echo.
python "%~dp0tracker\tracker.py" --preview
pause
