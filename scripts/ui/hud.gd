extends CanvasLayer

## WIGGLE WARS! — Universal In-Game HUD
## Displays level title, prominent 60-second countdown timer, instructions,
## camera status, live video PiP, subtitles for spoken dialogue, and pause menu.
## Scoring and combo displays completely removed per design requirement.

var title_label: Label
var timer_label: Label
var instruction_label: Label
var cam_status_rect: ColorRect
var cam_status_label: Label

@onready var video_pip: TextureRect = get_node_or_null("VideoPiP")
@onready var subtitle_panel: PanelContainer = get_node_or_null("SubtitlePanel")
@onready var subtitle_label: Label = get_node_or_null("SubtitlePanel/Margin/SubtitleLabel")
@onready var pause_menu: Control = get_node_or_null("PauseMenu")

var subtitle_timer: float = 0.0
var _nodes_resolved: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_nodes()
	
	if subtitle_panel:
		subtitle_panel.visible = false
	if pause_menu:
		pause_menu.visible = false
	
	AudioManager.subtitle_requested.connect(_on_subtitle_requested)
	GestureListener.tracker_connected.connect(_on_tracker_connected)
	GestureListener.tracker_disconnected.connect(_on_tracker_disconnected)
	GestureListener.frame_received.connect(_on_frame_received)
	
	if video_pip and GestureListener.current_frame_texture:
		video_pip.texture = GestureListener.current_frame_texture
		var pip_lbl: Label = get_node_or_null("VideoPiP/PiPLabel")
		if pip_lbl:
			pip_lbl.text = "LIVE CAMERA 📷"
			
	_update_cam_status(GestureListener.is_tracker_connected)
	set_timer(45.0)

func _resolve_nodes() -> void:
	if _nodes_resolved:
		return
	
	title_label = _find_label(["TopBar/HBox/LevelTitle", "TopBar/LevelTitle", "LevelTitle"])
	timer_label = _find_label(["TopBar/HBox/TimerLabel", "TopBar/TimerLabel", "TimerLabel", "TopBar/HBox/ScoreLabel", "TopBar/ScoreLabel"])
	instruction_label = _find_label(["TopBar/HBox/InstructionLabel", "TopBar/InstructionLabel", "InstructionLabel"])
	cam_status_rect = _find_color_rect(["TopBar/HBox/CamStatusIndicator", "TopBar/CamStatusIndicator", "CamStatusIndicator"])
	cam_status_label = _find_label(["TopBar/HBox/CamStatusLabel", "TopBar/CamStatusLabel", "CamStatusLabel"])
	
	_nodes_resolved = true

func _find_label(paths: Array[String]) -> Label:
	for p in paths:
		var n := get_node_or_null(p)
		if n is Label:
			return n
	return null

func _find_color_rect(paths: Array[String]) -> ColorRect:
	for p in paths:
		var n := get_node_or_null(p)
		if n is ColorRect:
			return n
	return null

func setup_hud(level_title: String, initial_instruction: String) -> void:
	_resolve_nodes()
	if title_label:
		title_label.text = level_title
	if instruction_label:
		instruction_label.text = initial_instruction

func set_instruction(text: String) -> void:
	_resolve_nodes()
	if instruction_label:
		instruction_label.text = text
		var tw := create_tween()
		tw.tween_property(instruction_label, "scale", Vector2(1.08, 1.08), 0.15)
		tw.tween_property(instruction_label, "scale", Vector2.ONE, 0.2)

func set_timer(remaining_seconds: float) -> void:
	_resolve_nodes()
	if not timer_label:
		return
	
	var clamped_sec := maxf(0.0, remaining_seconds)
	var mins := int(clamped_sec) / 60
	var secs := int(clamped_sec) % 60
	timer_label.text = "⏳ %02d:%02d" % [mins, secs]
	
	if clamped_sec <= 10.0 and clamped_sec > 0.0:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		timer_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.1, 0.1, 0.9))
	else:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
		timer_label.add_theme_color_override("font_shadow_color", Color(0.9, 0.4, 0.1, 0.8))

# Compatibility no-op stubs so existing calls do not break
func set_combo(_combo_count: int) -> void:
	pass

func show_floating_points(_amount: int, _col: Color = Color.WHITE) -> void:
	pass

func _process(delta: float) -> void:
	if subtitle_panel and subtitle_panel.visible:
		subtitle_timer -= delta
		if subtitle_timer <= 0.0:
			subtitle_panel.visible = false

func _on_subtitle_requested(text: String, duration: float) -> void:
	if subtitle_label and subtitle_panel:
		subtitle_label.text = text
		subtitle_panel.visible = true
		subtitle_timer = duration

func _on_tracker_connected() -> void:
	_update_cam_status(true)

func _on_tracker_disconnected() -> void:
	_update_cam_status(false)

func _update_cam_status(connected: bool) -> void:
	_resolve_nodes()
	if cam_status_rect:
		cam_status_rect.color = Color(0.1, 1.0, 0.4) if connected else Color(1.0, 0.25, 0.25)
	if cam_status_label:
		cam_status_label.text = "TRACKER ACTIVE" if connected else "TRACKER OFFLINE"
		cam_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5) if connected else Color(1.0, 0.4, 0.4))
	var pip_lbl: Label = get_node_or_null("VideoPiP/PiPLabel")
	if pip_lbl:
		if connected:
			pip_lbl.text = "LIVE CAMERA 📷"
		else:
			pip_lbl.text = "CAMERA OFFLINE"

func _on_frame_received(tex: ImageTexture) -> void:
	if video_pip:
		video_pip.texture = tex
	var pip_lbl: Label = get_node_or_null("VideoPiP/PiPLabel")
	if pip_lbl and pip_lbl.text != "LIVE CAMERA 📷":
		pip_lbl.text = "LIVE CAMERA 📷"
	_update_cam_status(true)

func _on_pause_btn_pressed() -> void:
	_toggle_pause()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	if pause_menu:
		pause_menu.visible = paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	if pause_menu:
		pause_menu.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.load_level(GameManager.current_level)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.return_to_main_menu()
