extends Control

## WIGGLE WARS! — Webcam Setup & Calibration Screen
## Provides live webcam preview, tracking telemetry feedback,
## lighting instructions, calibration, and retry controls.

@onready var video_preview: TextureRect = $Content/HBox/LeftCol/PreviewPanel/VideoPreview
@onready var status_badge: Label = $Content/HBox/LeftCol/StatusBadge
@onready var face_feedback: Label = $Content/HBox/RightCol/GesturesBox/FaceFeedback
@onready var hand_feedback: Label = $Content/HBox/RightCol/GesturesBox/HandFeedback
@onready var pose_feedback: Label = $Content/HBox/RightCol/GesturesBox/PoseFeedback
@onready var continue_btn: Button = $Content/BottomBar/ContinueBtn
@onready var retry_btn: Button = $Content/BottomBar/RetryBtn
@onready var calibrate_btn: Button = $Content/BottomBar/CalibrateBtn

var tested_face: bool = false
var tested_hand: bool = false
var tested_pose: bool = false

func _ready() -> void:
	GestureListener.tracker_connected.connect(_on_tracker_connected)
	GestureListener.tracker_disconnected.connect(_on_tracker_disconnected)
	GestureListener.frame_received.connect(_on_frame_received)
	GestureListener.face_detected.connect(_on_face_detected)
	GestureListener.hand_detected.connect(_on_hand_detected)
	GestureListener.pose_detected.connect(_on_pose_detected)

	_update_connection_ui(GestureListener.is_tracker_connected)
	AudioManager.play_voice_file("res://assets/audio/lumi_welcome.wav", 
		"Welcome to Wiggle Wars! I'm Lumi, your magical guide. Let's make sure your camera can see you!", 5.0)

func _update_connection_ui(connected: bool) -> void:
	if connected:
		status_badge.text = "● CAMERA CONNECTED & ACTIVE"
		status_badge.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	else:
		status_badge.text = "○ WAITING FOR TRACKER (Run launch_tracker.bat)"
		status_badge.add_theme_color_override("font_color", Color(0.95, 0.4, 0.2))

func _on_tracker_connected() -> void:
	_update_connection_ui(true)

func _on_tracker_disconnected() -> void:
	_update_connection_ui(false)

func _on_frame_received(tex: ImageTexture) -> void:
	if video_preview:
		video_preview.texture = tex

func _on_face_detected(expr: String, _scores: Dictionary, _eye_closed: float) -> void:
	if expr != "neutral":
		tested_face = true
		face_feedback.text = "Face detected: %s! ✔" % expr.to_upper()
		face_feedback.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))

func _on_hand_detected(_pos: Vector2, swipe: String, waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if waving or swipe != "none":
		tested_hand = true
		var action_text := "WAVING" if waving else swipe.to_upper()
		hand_feedback.text = "Hand detected: %s! ✔" % action_text
		hand_feedback.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))

func _on_pose_detected(gest: String, _lean: String, _lean_amt: float, _hr: bool, _ae: bool, _sq: bool, _cd: bool) -> void:
	if gest != "neutral":
		tested_pose = true
		pose_feedback.text = "Pose detected: %s! ✔" % gest.to_upper()
		pose_feedback.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))

func _on_calibrate_pressed() -> void:
	GestureListener.request_pose_calibration()
	AudioManager.play_sfx("chime")
	pose_feedback.text = "Pose calibrated! Stand naturally."

func _on_retry_pressed() -> void:
	_update_connection_ui(GestureListener.is_tracker_connected)

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.load_level(1)

func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()
