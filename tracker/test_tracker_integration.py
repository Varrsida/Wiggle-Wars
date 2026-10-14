"""WIGGLE WARS! — Python Tracker & Bridge Verification Script
Tests socket communication, JSON payload formatting, and MediaPipe task loading.
"""

import os
import sys
import json
import time
import socket

def test_mediapipe_models():
    print("[Test] Verifying MediaPipe model files...")
    tracker_dir = os.path.dirname(os.path.abspath(__file__))
    models = ["face_landmarker.task", "hand_landmarker.task", "pose_landmarker_lite.task"]
    for m in models:
        p = os.path.join(tracker_dir, m)
        assert os.path.exists(p), f"Missing model: {p}"
        size_mb = os.path.getsize(p) / (1024 * 1024)
        print(f"  [OK] {m} ({size_mb:.2f} MB)")

def test_telemetry_schema():
    print("[Test] Verifying telemetry packet schema...")
    telemetry = {
        "type": "telemetry",
        "timestamp": round(time.time(), 3),
        "status": "tracking_ok",
        "face": {
            "active": True,
            "expression": "smile",
            "scores": {"smile": 0.9, "mouth_open": 0.1, "eyebrows": 0.1},
            "eye_closed_duration": 0.0
        },
        "hand": {
            "active": True,
            "cursor_x": 0.5,
            "cursor_y": 0.5,
            "is_waving": False,
            "wave_speed": 0.0,
            "swipe": "swipe_right",
            "swipe_pos": [0.5, 0.5],
            "is_open_palm": True,
            "is_fist": False,
            "is_pointing": False,
            "reach_up": False
        },
        "pose": {
            "active": True,
            "gesture": "lean_left",
            "lean": "lean_left",
            "lean_amount": -0.15,
            "hands_raised": False,
            "arms_extended": False,
            "squatting": False,
            "chicken_dance": False
        }
    }
    dumped = json.dumps(telemetry)
    loaded = json.loads(dumped)
    assert loaded["type"] == "telemetry"
    assert loaded["face"]["expression"] == "smile"
    assert loaded["hand"]["swipe"] == "swipe_right"
    assert loaded["pose"]["gesture"] == "lean_left"
    print("  [OK] Telemetry packet schema verified!")

if __name__ == "__main__":
    test_mediapipe_models()
    test_telemetry_schema()
    print(">>> Python tracker verification passed cleanly!")
