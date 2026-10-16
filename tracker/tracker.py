"""WIGGLE WARS! — Multi-Modal Python Webcam Gesture Tracker & Speech Bridge
Integrates MediaPipe FaceLandmarker, HandLandmarker, PoseLandmarker,
live JPEG frame streaming to Godot (TCP 9998), JSON-lines telemetry (TCP 9999),
and real SpeechRecognition + Text-To-Speech (pyttsx3) for Copycat Chaos (Level 4).
"""

import sys
import os
import time
import json
import socket
import threading
import math
import cv2
import numpy as np

import mediapipe as mp
from mediapipe.tasks.python import vision
from mediapipe.tasks.python import BaseOptions

# Optional speech recognition and TTS
try:
    import speech_recognition as sr
    SPEECH_AVAILABLE = True
except Exception:
    SPEECH_AVAILABLE = False

try:
    import pyttsx3
    TTS_AVAILABLE = True
except Exception:
    TTS_AVAILABLE = False


class TrackerConfig:
    HOST = "127.0.0.1"
    TELEMETRY_PORT = 9999
    FRAME_STREAM_PORT = 9998
    
    CAMERA_INDEX = 0
    FRAME_WIDTH = 640
    FRAME_HEIGHT = 480
    PREVIEW_WIDTH = 320
    PREVIEW_HEIGHT = 240
    TARGET_FPS = 30
    
    # Face thresholds (tuned for natural player expressions)
    SMILE_THRESHOLD = 0.30
    MOUTH_OPEN_THRESHOLD = 0.28
    EYEBROW_RAISE_THRESHOLD = 0.26
    EYE_BLINK_THRESHOLD = 0.48
    SUSTAINED_BLINK_SECONDS = 0.75
    SURPRISED_JAW_THRESHOLD = 0.26
    SURPRISED_BROW_THRESHOLD = 0.24
    
    # Hand thresholds (tuned for natural responsive swipes and waves)
    SWIPE_MIN_DISTANCE = 0.07  # normalized distance
    SWIPE_MAX_TIME = 0.35      # seconds
    WAVE_MIN_PEAKS = 2
    
    # Pose thresholds (tuned for responsive waddling, leaning and jumping)
    LEAN_LEFT_THRESHOLD = -0.06
    LEAN_RIGHT_THRESHOLD = 0.06
    HANDS_RAISED_Y_MARGIN = 0.05
    ARMS_EXTENDED_SPAN_RATIO = 1.60
    SQUAT_DROP_THRESHOLD = 0.06


DIR_PATH = os.path.dirname(os.path.abspath(__file__))
POSE_MODEL_PATH = os.path.join(DIR_PATH, "pose_landmarker_lite.task")
HAND_MODEL_PATH = os.path.join(DIR_PATH, "hand_landmarker.task")
FACE_MODEL_PATH = os.path.join(DIR_PATH, "face_landmarker.task")
AUDIO_OUTPUT_DIR = os.path.join(os.path.dirname(DIR_PATH), "assets", "audio")


class FrameServer:
    """Streams live compressed JPEG camera frames to Godot with 4-byte big-endian header."""
    def __init__(self, host=TrackerConfig.HOST, port=TrackerConfig.FRAME_STREAM_PORT):
        self.host = host
        self.port = port
        self.server_sock = None
        self.clients = []
        self.clients_lock = threading.Lock()
        self.running = False
        self.thread = None

    def start(self):
        try:
            self.server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_sock.bind((self.host, self.port))
            self.server_sock.listen(2)
            self.server_sock.settimeout(0.5)
            self.running = True
            self.thread = threading.Thread(target=self._accept_loop, daemon=True)
            self.thread.start()
            print(f"[FrameServer] Serving webcam video on {self.host}:{self.port}")
        except Exception as e:
            print(f"[FrameServer] Failed to bind frame server on {self.port}: {e}")

    def _accept_loop(self):
        while self.running:
            try:
                client, addr = self.server_sock.accept()
                client.settimeout(0.5)
                with self.clients_lock:
                    self.clients.append(client)
                print(f"[FrameServer] Godot video client connected from {addr}")
            except socket.timeout:
                continue
            except Exception:
                break

    def broadcast_frame(self, jpeg_bytes):
        if not jpeg_bytes:
            return
        length_prefix = len(jpeg_bytes).to_bytes(4, byteorder='big')
        packet = length_prefix + jpeg_bytes
        disconnected = []
        with self.clients_lock:
            for client in self.clients:
                try:
                    client.sendall(packet)
                except Exception:
                    disconnected.append(client)
            for c in disconnected:
                self.clients.remove(c)
                try:
                    c.close()
                except Exception:
                    pass

    def stop(self):
        self.running = False
        with self.clients_lock:
            for client in self.clients:
                try:
                    client.close()
                except Exception:
                    pass
            self.clients.clear()
        if self.server_sock:
            try:
                self.server_sock.close()
            except Exception:
                pass


class SpeechHandler:
    """Manages real microphone capture, speech recognition, and TTS repeats."""
    def __init__(self, callback_send):
        self.callback_send = callback_send
        self.recognizer = sr.Recognizer() if SPEECH_AVAILABLE else None
        self.is_listening = False
        self.tts_lock = threading.Lock()
        os.makedirs(AUDIO_OUTPUT_DIR, exist_ok=True)

    def trigger_listen(self, prompt="Say something funny!"):
        if not SPEECH_AVAILABLE:
            self.callback_send({
                "type": "speech_status",
                "status": "unavailable",
                "message": "Speech recognition library not available."
            })
            return

        if self.is_listening:
            return

        thread = threading.Thread(target=self._listen_worker, daemon=True)
        thread.start()

    def _listen_worker(self):
        self.is_listening = True
        self.callback_send({
            "type": "speech_status",
            "status": "listening",
            "message": "Listening... Speak now!"
        })
        try:
            with sr.Microphone() as source:
                self.recognizer.adjust_for_ambient_noise(source, duration=0.6)
                print("[Speech] Listening for audio...")
                audio = self.recognizer.listen(source, timeout=4.0, phrase_time_limit=4.0)

            print("[Speech] Processing audio...")
            self.callback_send({
                "type": "speech_status",
                "status": "processing",
                "message": "Recognizing words..."
            })
            
            try:
                # Real speech recognition via Google Web Speech API
                text = self.recognizer.recognize_google(audio)
                print(f"[Speech] Recognized: '{text}'")
                
                # Generate TTS file for Godot to play
                out_path = os.path.join(AUDIO_OUTPUT_DIR, "shinchan_repeat.wav")
                self.speak_and_save(text, out_path)
                
                self.callback_send({
                    "type": "speech_result",
                    "success": True,
                    "text": text,
                    "audio_file": "res://assets/audio/shinchan_repeat.wav",
                    "timestamp": time.time()
                })
            except sr.UnknownValueError:
                print("[Speech] Could not understand audio.")
                self.callback_send({
                    "type": "speech_result",
                    "success": False,
                    "text": "",
                    "error": "I didn't catch that! Try again!",
                    "timestamp": time.time()
                })
            except Exception as e:
                print(f"[Speech] Recognition error: {e}")
                self.callback_send({
                    "type": "speech_result",
                    "success": False,
                    "text": "",
                    "error": str(e),
                    "timestamp": time.time()
                })
        except Exception as e:
            print(f"[Speech] Microphone error: {e}")
            self.callback_send({
                "type": "speech_status",
                "status": "error",
                "message": "Microphone not detected or accessible. You can also wave, dance, and pose with Shinchan!"
            })
        finally:
            self.is_listening = False

    def speak_and_save(self, text, output_wav):
        if not TTS_AVAILABLE:
            return
        with self.tts_lock:
            try:
                engine = pyttsx3.init()
                # Pick a funny voice setting: higher pitch / faster rate for Shinchan style
                engine.setProperty('rate', 190)
                voices = engine.getProperty('voices')
                # Prefer David or default voice
                for v in voices:
                    if "david" in v.name.lower() or "male" in v.name.lower():
                        engine.setProperty('voice', v.id)
                        break
                engine.save_to_file(text, output_wav)
                engine.runAndWait()
            except Exception as e:
                print(f"[TTS] Error generating speech: {e}")


class MultiModalTracker:
    def __init__(self, host=TrackerConfig.HOST, port=TrackerConfig.TELEMETRY_PORT):
        self.host = host
        self.port = port
        self.sock = None
        self.is_connected = False
        self.sock_lock = threading.Lock()
        
        # Telemetry state
        self.cursor_x = 0.5
        self.cursor_y = 0.5
        self.face_expression = "neutral"
        self.face_scores = {"smile": 0.0, "mouth_open": 0.0, "eyebrows": 0.0, "wink_left": 0.0, "wink_right": 0.0}
        self.face_detected = False
        
        # Eyes closed timer
        self.blink_start_time = 0.0
        self.eye_closed_duration = 0.0
        self.is_sleepy_active = False
        
        # Hand tracking & swipes
        self.hand_detected = False
        self.is_pointing = False
        self.is_pinching = False
        self.is_open_palm = False
        self.is_fist = False
        self.hand_history = []  # list of (time, x, y)
        self.recent_swipe = "none"
        self.recent_swipe_time = 0.0
        self.swipe_pos = [0.5, 0.5]
        self.is_waving = False
        self.wave_speed = 0.0
        self.reach_up = False
        
        # Pose tracking
        self.pose_detected = False
        self.pose_gesture = "neutral"
        self.lean_state = "neutral"
        self.lean_amount = 0.0
        self.baseline_hip_y = None
        self.squatting = False
        self.arms_extended = False
        self.hands_raised = False
        self.left_arm_raised = False
        self.right_arm_raised = False
        self.hero_pose = False
        self.chicken_dance = False
        self.elbow_history = []
        self.head_tilt = "center"
        self.head_tilt_angle = 0.0
        
        # Models
        self.pose_detector = None
        self.hand_detector = None
        self.face_detector = None
        self._init_models()
        
        # Speech handler
        self.speech_handler = SpeechHandler(self.send_telemetry)
        
        # Inbound command listener thread
        self.command_thread = None

    def _init_models(self):
        if os.path.exists(POSE_MODEL_PATH):
            try:
                opts = vision.PoseLandmarkerOptions(
                    base_options=BaseOptions(model_asset_path=POSE_MODEL_PATH),
                    output_segmentation_masks=False,
                    running_mode=vision.RunningMode.IMAGE
                )
                self.pose_detector = vision.PoseLandmarker.create_from_options(opts)
                print("[Tracker] PoseLandmarker initialized.")
            except Exception as e:
                print(f"[Tracker] PoseLandmarker error: {e}")

        if os.path.exists(HAND_MODEL_PATH):
            try:
                opts = vision.HandLandmarkerOptions(
                    base_options=BaseOptions(model_asset_path=HAND_MODEL_PATH),
                    num_hands=2,
                    running_mode=vision.RunningMode.IMAGE
                )
                self.hand_detector = vision.HandLandmarker.create_from_options(opts)
                print("[Tracker] HandLandmarker initialized.")
            except Exception as e:
                print(f"[Tracker] HandLandmarker error: {e}")

        if os.path.exists(FACE_MODEL_PATH):
            try:
                opts = vision.FaceLandmarkerOptions(
                    base_options=BaseOptions(model_asset_path=FACE_MODEL_PATH),
                    output_face_blendshapes=True,
                    running_mode=vision.RunningMode.IMAGE
                )
                self.face_detector = vision.FaceLandmarker.create_from_options(opts)
                print("[Tracker] FaceLandmarker initialized.")
            except Exception as e:
                print(f"[Tracker] FaceLandmarker error: {e}")

    def connect_socket(self):
        with self.sock_lock:
            try:
                if self.sock:
                    try:
                        self.sock.close()
                    except Exception:
                        pass
                self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.sock.settimeout(0.2)
                self.sock.connect((self.host, self.port))
                self.is_connected = True
                print(f"[Tracker] Connected to Godot TCP telemetry server at {self.host}:{self.port}")
                
                # Start background command listener for requests from Godot (e.g. listen_speech)
                if not self.command_thread or not self.command_thread.is_alive():
                    self.command_thread = threading.Thread(target=self._command_listener_loop, daemon=True)
                    self.command_thread.start()
                return True
            except (socket.error, ConnectionRefusedError):
                self.is_connected = False
                return False

    def _command_listener_loop(self):
        """Listens for commands from Godot (e.g. speech trigger, calibration)."""
        buffer = ""
        while self.is_connected:
            try:
                data = self.sock.recv(1024)
                if not data:
                    break
                buffer += data.decode("utf-8")
                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        cmd = json.loads(line)
                        self._handle_incoming_command(cmd)
                    except Exception as e:
                        print(f"[Tracker] Error parsing incoming command: {e}")
            except socket.timeout:
                continue
            except Exception:
                break
        self.is_connected = False

    def _handle_incoming_command(self, cmd):
        action = cmd.get("action")
        print(f"[Tracker] Received command from Godot: {action}")
        if action == "listen_speech":
            self.speech_handler.trigger_listen()
        elif action == "calibrate":
            self.baseline_hip_y = None
            print("[Tracker] Calibrated baseline pose.")

    def send_telemetry(self, telemetry_dict):
        if not self.is_connected:
            self.connect_socket()

        if self.is_connected and self.sock:
            with self.sock_lock:
                try:
                    data = json.dumps(telemetry_dict) + "\n"
                    self.sock.sendall(data.encode("utf-8"))
                except (socket.error, BrokenPipeError):
                    self.is_connected = False

    # --------------------------------------------------------------------------
    # FACE EXPRESSION TRACKING
    # --------------------------------------------------------------------------
    def process_face(self, mp_image, now):
        if not self.face_detector:
            return
        res = self.face_detector.detect(mp_image)
        
        if res.face_blendshapes and len(res.face_blendshapes) > 0:
            self.face_detected = True
            cats = {c.category_name: c.score for c in res.face_blendshapes[0]}
            
            smile_l = cats.get("mouthSmileLeft", 0.0)
            smile_r = cats.get("mouthSmileRight", 0.0)
            smile_score = (smile_l + smile_r) * 0.5
            
            mouth_open = cats.get("jawOpen", 0.0)
            brow_up = cats.get("browInnerUp", 0.0)
            blink_l = cats.get("eyeBlinkLeft", 0.0)
            blink_r = cats.get("eyeBlinkRight", 0.0)
            
            # Eye closure duration
            both_eyes_closed = (blink_l > TrackerConfig.EYE_BLINK_THRESHOLD and blink_r > TrackerConfig.EYE_BLINK_THRESHOLD)
            if both_eyes_closed:
                if self.blink_start_time == 0.0:
                    self.blink_start_time = now
                self.eye_closed_duration = now - self.blink_start_time
            else:
                self.blink_start_time = 0.0
                self.eye_closed_duration = now - self.blink_start_time if self.blink_start_time > 0 else 0.0

            # Head tilt detection from eye landmarks
            self.head_tilt = "center"
            self.head_tilt_angle = 0.0
            if res.face_landmarks and len(res.face_landmarks) > 0:
                lms = res.face_landmarks[0]
                if len(lms) > 263:
                    dx = lms[263].x - lms[33].x
                    dy = lms[263].y - lms[33].y
                    self.head_tilt_angle = round(float(math.degrees(math.atan2(dy, dx))), 1)
                    if self.head_tilt_angle < -12.0:
                        self.head_tilt = "tilt_left"
                    elif self.head_tilt_angle > 12.0:
                        self.head_tilt = "tilt_right"

            self.face_scores = {
                "smile": round(float(smile_score), 3),
                "mouth_open": round(float(mouth_open), 3),
                "eyebrows": round(float(brow_up), 3),
                "wink_left": round(float(blink_l), 3),
                "wink_right": round(float(blink_r), 3),
                "head_tilt_angle": self.head_tilt_angle
            }
            
            # Classification logic
            # 1. Sustained eye closure (sleepy garden)
            if self.eye_closed_duration >= TrackerConfig.SUSTAINED_BLINK_SECONDS:
                self.face_expression = "sleepy"
            # 2. Surprised expression (wide jaw + high eyebrows)
            elif (mouth_open > TrackerConfig.SURPRISED_JAW_THRESHOLD and 
                  brow_up > TrackerConfig.SURPRISED_BROW_THRESHOLD):
                self.face_expression = "surprised"
            # 3. Smile
            elif smile_score > TrackerConfig.SMILE_THRESHOLD:
                self.face_expression = "smile"
            # 4. Open mouth
            elif mouth_open > TrackerConfig.MOUTH_OPEN_THRESHOLD:
                self.face_expression = "mouth_open"
            # 5. Eyebrow raise
            elif brow_up > TrackerConfig.EYEBROW_RAISE_THRESHOLD:
                self.face_expression = "eyebrows"
            # 6. Head tilt
            elif self.head_tilt != "center":
                self.face_expression = "head_tilt"
            else:
                self.face_expression = "neutral"
        else:
            self.face_detected = False
            self.face_expression = "neutral"
            self.head_tilt = "center"
            self.head_tilt_angle = 0.0
            self.eye_closed_duration = 0.0
            self.blink_start_time = 0.0

    # --------------------------------------------------------------------------
    # HAND TRACKING & SWIPES
    # --------------------------------------------------------------------------
    def process_hands(self, mp_image, now):
        if not self.hand_detector:
            return
        res = self.hand_detector.detect(mp_image)
        if res.hand_landmarks and len(res.hand_landmarks) > 0:
            self.hand_detected = True
            primary_hand = res.hand_landmarks[0]
            
            idx_tip = primary_hand[8]
            self.cursor_x = round(float(idx_tip.x), 4)
            self.cursor_y = round(float(idx_tip.y), 4)
            
            # Reaching upward
            self.reach_up = (idx_tip.y < 0.18)
            
            # Record hand history for swipes & wave
            self.hand_history.append((now, idx_tip.x, idx_tip.y))
            # Keep history within last 0.4 seconds
            self.hand_history = [h for h in self.hand_history if (now - h[0]) <= 0.4]
            
            # Swipe detection
            if len(self.hand_history) >= 4 and (now - self.recent_swipe_time) > 0.4:
                old_t, old_x, old_y = self.hand_history[0]
                dt = now - old_t
                dx = idx_tip.x - old_x
                dy = idx_tip.y - old_y
                
                if dt > 0.04 and dt < TrackerConfig.SWIPE_MAX_TIME:
                    dist = math.sqrt(dx*dx + dy*dy)
                    if dist >= TrackerConfig.SWIPE_MIN_DISTANCE:
                        if abs(dx) > abs(dy):
                            self.recent_swipe = "swipe_left" if dx < 0 else "swipe_right"
                        else:
                            self.recent_swipe = "swipe_up" if dy < 0 else "swipe_down"
                        self.recent_swipe_time = now
                        self.swipe_pos = [self.cursor_x, self.cursor_y]
            
            # Hand wave detection (horizontal oscillations)
            if len(self.hand_history) >= 8:
                xs = [h[1] for h in self.hand_history]
                diffs = [xs[i+1] - xs[i] for i in range(len(xs)-1)]
                sign_changes = sum(1 for i in range(len(diffs)-1) if (diffs[i] * diffs[i+1]) < 0)
                span = max(xs) - min(xs)
                if sign_changes >= 2 and span > 0.08:
                    self.is_waving = True
                    self.wave_speed = round(float(span / 0.4), 2)
                else:
                    self.is_waving = False
                    self.wave_speed = 0.0
            else:
                self.is_waving = False
            
            # Check open palm / fist / pointing
            idx_extended = primary_hand[8].y < primary_hand[6].y
            mid_extended = primary_hand[12].y < primary_hand[10].y
            ring_extended = primary_hand[16].y < primary_hand[14].y
            pnk_extended = primary_hand[20].y < primary_hand[18].y
            
            self.is_open_palm = idx_extended and mid_extended and ring_extended and pnk_extended
            self.is_fist = (not idx_extended) and (not mid_extended) and (not ring_extended) and (not pnk_extended)
            self.is_pointing = idx_extended and (not mid_extended) and (not ring_extended)
        else:
            self.hand_detected = False
            self.is_waving = False
            self.is_open_palm = False
            self.is_fist = False
            self.is_pointing = False
            self.reach_up = False

        # Expire recent swipe after 0.25s
        if (now - self.recent_swipe_time) > 0.25:
            self.recent_swipe = "none"

    # --------------------------------------------------------------------------
    # POSE TRACKING
    # --------------------------------------------------------------------------
    def process_pose(self, mp_image, now):
        if not self.pose_detector:
            return
        res = self.pose_detector.detect(mp_image)
        if res.pose_landmarks and len(res.pose_landmarks) > 0:
            self.pose_detected = True
            lm = res.pose_landmarks[0]
            
            l_sh = lm[11]
            r_sh = lm[12]
            l_el = lm[13]
            r_el = lm[14]
            l_wr = lm[15]
            r_wr = lm[16]
            l_hip = lm[23]
            r_hip = lm[24]
            
            shoulder_y = (l_sh.y + r_sh.y) * 0.5
            shoulder_span = abs(l_sh.x - r_sh.x)
            if shoulder_span < 0.05:
                shoulder_span = 0.2
            wrist_span = abs(l_wr.x - r_wr.x)
            hip_y = (l_hip.y + r_hip.y) * 0.5
            
            # Calibrate baseline hip level
            if self.baseline_hip_y is None and hip_y > 0.1:
                self.baseline_hip_y = hip_y
            
            # 1. Independent Arm Raises & Hands Raised
            self.left_arm_raised = bool(l_wr.y < (shoulder_y - TrackerConfig.HANDS_RAISED_Y_MARGIN))
            self.right_arm_raised = bool(r_wr.y < (shoulder_y - TrackerConfig.HANDS_RAISED_Y_MARGIN))
            self.hands_raised = bool(self.left_arm_raised and self.right_arm_raised)
            
            # 2. Hero Pose (one arm thrust high diagonal, other hand lowered/hip)
            self.hero_pose = bool((self.left_arm_raised ^ self.right_arm_raised) and abs(l_wr.y - r_wr.y) > 0.25)
            
            # 3. Arms Extended Sideways (Penguin balance / flippers)
            self.arms_extended = bool(wrist_span > (shoulder_span * TrackerConfig.ARMS_EXTENDED_SPAN_RATIO) and
                                      abs(l_wr.y - shoulder_y) < 0.25 and abs(r_wr.y - shoulder_y) < 0.25)
            
            # 4. Squatting (Penguin pose)
            if self.baseline_hip_y is not None:
                self.squatting = bool((hip_y - self.baseline_hip_y) > TrackerConfig.SQUAT_DROP_THRESHOLD)
            else:
                self.squatting = False
            
            # 5. Lean detection (Left / Right)
            sh_center_x = (l_sh.x + r_sh.x) * 0.5
            hip_center_x = (l_hip.x + r_hip.x) * 0.5
            lean_offset = sh_center_x - hip_center_x
            self.lean_amount = round(float(lean_offset), 3)
            
            if lean_offset < TrackerConfig.LEAN_LEFT_THRESHOLD:
                self.lean_state = "lean_left"
            elif lean_offset > TrackerConfig.LEAN_RIGHT_THRESHOLD:
                self.lean_state = "lean_right"
            else:
                self.lean_state = "neutral"
            
            # 6. Lean Forward (Belly slide)
            # Torso height compression when leaning forward
            torso_height = abs(hip_y - shoulder_y)
            lean_forward = bool(torso_height < 0.22 and shoulder_y > 0.35)
            
            # 7. Chicken dance (elbow flapping rhythm)
            self.elbow_history.append((now, l_el.y, r_el.y))
            self.elbow_history = [e for e in self.elbow_history if (now - e[0]) <= 0.8]
            if len(self.elbow_history) >= 6:
                ely = [e[1] for e in self.elbow_history]
                el_diff = max(ely) - min(ely)
                self.chicken_dance = bool(el_diff > 0.08 and abs(l_wr.y - shoulder_y) < 0.2)
            else:
                self.chicken_dance = False

            # Consolidate primary pose gesture
            if self.chicken_dance:
                self.pose_gesture = "chicken_dance"
            elif self.hands_raised:
                self.pose_gesture = "hands_raised"
            elif self.hero_pose:
                self.pose_gesture = "hero_pose"
            elif self.left_arm_raised:
                self.pose_gesture = "left_arm_raised"
            elif self.right_arm_raised:
                self.pose_gesture = "right_arm_raised"
            elif self.arms_extended:
                self.pose_gesture = "arms_extended"
            elif self.squatting:
                self.pose_gesture = "squat"
            elif lean_forward:
                self.pose_gesture = "lean_forward"
            elif self.lean_state != "neutral":
                self.pose_gesture = self.lean_state
            else:
                self.pose_gesture = "neutral"
        else:
            self.pose_detected = False
            self.pose_gesture = "neutral"
            self.lean_state = "neutral"
            self.lean_amount = 0.0
            self.hands_raised = False
            self.left_arm_raised = False
            self.right_arm_raised = False
            self.hero_pose = False
            self.arms_extended = False
            self.squatting = False
            self.chicken_dance = False

    # --------------------------------------------------------------------------
    # TELEMETRY PACKET BUILDER
    # --------------------------------------------------------------------------
    def build_telemetry(self, now):
        telemetry = {
            "type": "telemetry",
            "timestamp": round(now, 3),
            "status": "tracking_ok",
            "face": {
                "active": self.face_detected,
                "expression": self.face_expression,
                "scores": self.face_scores,
                "head_tilt": self.head_tilt,
                "eye_closed_duration": round(float(self.eye_closed_duration), 2)
            },
            "hand": {
                "active": self.hand_detected,
                "cursor_x": self.cursor_x,
                "cursor_y": self.cursor_y,
                "is_waving": self.is_waving,
                "wave_speed": self.wave_speed,
                "swipe": self.recent_swipe,
                "swipe_pos": self.swipe_pos,
                "is_open_palm": self.is_open_palm,
                "is_fist": self.is_fist,
                "is_pointing": self.is_pointing,
                "reach_up": self.reach_up
            },
            "pose": {
                "active": self.pose_detected,
                "gesture": self.pose_gesture,
                "lean": self.lean_state,
                "lean_amount": self.lean_amount,
                "hands_raised": self.hands_raised,
                "left_arm_raised": self.left_arm_raised,
                "right_arm_raised": self.right_arm_raised,
                "hero_pose": self.hero_pose,
                "arms_extended": self.arms_extended,
                "squatting": self.squatting,
                "chicken_dance": self.chicken_dance
            }
        }
        return telemetry


# ==============================================================================
# MAIN TRACKER LOOP
# ==============================================================================
def run_tracker(camera_index=TrackerConfig.CAMERA_INDEX, show_preview=False):
    print("=" * 65)
    print(">>> WIGGLE WARS! — MULTI-MODAL GESTURE TRACKER")
    print(f">>> SPEECH RECOGNITION: {'ENABLED' if SPEECH_AVAILABLE else 'UNAVAILABLE'}")
    print(f">>> TEXT-TO-SPEECH (TTS): {'ENABLED' if TTS_AVAILABLE else 'UNAVAILABLE'}")
    print("=" * 65)

    tracker = MultiModalTracker()
    frame_server = FrameServer()
    frame_server.start()

    cap = cv2.VideoCapture(camera_index)
    if not cap.isOpened():
        print(f"[Tracker] FATAL: Unable to open camera index {camera_index}!")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, TrackerConfig.FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, TrackerConfig.FRAME_HEIGHT)
    cap.set(cv2.CAP_PROP_FPS, TrackerConfig.TARGET_FPS)

    print("[Tracker] Camera initialized successfully. Starting vision loop...")

    try:
        while True:
            ret, frame = cap.read()
            if not ret or frame is None:
                time.sleep(0.01)
                continue

            now = time.time()
            frame = cv2.flip(frame, 1)  # Mirror view
            
            # Prepare image for MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)

            # Process all 3 modalities
            tracker.process_face(mp_image, now)
            tracker.process_hands(mp_image, now)
            tracker.process_pose(mp_image, now)

            # Build and send telemetry JSON
            telemetry = tracker.build_telemetry(now)
            tracker.send_telemetry(telemetry)

            # Encode and broadcast preview frame for Godot HUD/Webcam Setup
            preview_frame = cv2.resize(frame, (TrackerConfig.PREVIEW_WIDTH, TrackerConfig.PREVIEW_HEIGHT))
            _, jpeg_data = cv2.imencode('.jpg', preview_frame, [cv2.IMWRITE_JPEG_QUALITY, 70])
            frame_server.broadcast_frame(jpeg_data.tobytes())

            # Desktop debug preview
            if show_preview:
                # Annotate debug info
                cv2.putText(preview_frame, f"Face: {tracker.face_expression}", (10, 25), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                cv2.putText(preview_frame, f"Hand: {tracker.recent_swipe} (Wave:{tracker.is_waving})", (10, 50), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 1)
                cv2.putText(preview_frame, f"Pose: {tracker.pose_gesture}", (10, 75), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 200, 255), 1)
                cv2.imshow("WIGGLE WARS! Tracker Preview", preview_frame)
                if cv2.waitKey(1) & 0xFF == 27:
                    break

            time.sleep(1.0 / TrackerConfig.TARGET_FPS)

    except KeyboardInterrupt:
        print("[Tracker] Interrupted by user.")
    finally:
        cap.release()
        frame_server.stop()
        if show_preview:
            cv2.destroyAllWindows()
        print("[Tracker] Cleaned up and exited.")


if __name__ == "__main__":
    show_preview = "--preview" in sys.argv
    cam_idx = 0
    for i, arg in enumerate(sys.argv):
        if arg == "--camera" and i + 1 < len(sys.argv):
            try:
                cam_idx = int(sys.argv[i+1])
            except ValueError:
                pass
    run_tracker(camera_index=cam_idx, show_preview=show_preview)
