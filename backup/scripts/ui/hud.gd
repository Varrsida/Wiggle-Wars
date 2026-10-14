extends CanvasLayer

## WIGGLE WARS! — Universal In-Game HUD
## Displays level title, score, combo, camera status, live video PiP,
## subtitles for spoken dialogue, and pause menu.

var title_label: Label
var score_label: Label
var instruction_label: Label
var cam_status_rect: ColorRect
var cam_status_label: Label
var combo_label: Label

@onready var video_pip: TextureRect = get_node_or_null("VideoPiP")
@onready var subtitle_panel: PanelContainer = get_node_or_null("SubtitlePanel")
@onready var subtitle_label: Label = get_node_or_null("SubtitlePanel/Margin/SubtitleLabel")
@onready var pause_menu: Control = get_node_or_null("PauseMenu")
@onready var floating_points_container: Control = get_node_or_null("FloatingPoints")

var subtitle_timer: float = 0.0
var _nodes_resolved: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_nodes()
	
	if subtitle_panel:
		subtitle_panel.visible = false
	if pause_menu:
		pause_menu.visible = false
	
	GameManager.score_changed.connect(_on_score_changed)
	AudioManager.subtitle_requested.connect(_on_subtitle_requested)
	GestureListener.tracker_connected.connect(_on_tracker_connected)
	GestureListener.tracker_disconnected.connect(_on_tracker_disconnected)
	GestureListener.frame_received.connect(_on_frame_received)
	
	_update_cam_status(GestureListener.is_tracker_connected)
	_update_score_display()

func _resolve_nodes() -> void:
	if _nodes_resolved:
		return
	
	# Safe flexible resolution supporting both TopBar/HBox/... and TopBar/...
	title_label = _find_label(["TopBar/HBox/LevelTitle", "TopBar/LevelTitle", "LevelTitle"])
	score_label = _find_label(["TopBar/HBox/ScoreLabel", "TopBar/ScoreLabel", "ScoreLabel"])
	instruction_label = _find_label(["TopBar/HBox/InstructionLabel", "TopBar/InstructionLabel", "InstructionLabel"])
	combo_label = _find_label(["TopBar/HBox/ComboLabel", "TopBar/ComboLabel", "ComboLabel"])
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
		# Gentle pop animation on instruction change
		var tw := create_tween()
		tw.tween_property(instruction_label, "scale", Vector2(1.08, 1.08), 0.15)
		tw.tween_property(instruction_label, "scale", Vector2.ONE, 0.2)

func set_combo(combo_count: int) -> void:
	_resolve_nodes()
	if combo_label:
		if combo_count > 1:
			combo_label.visible = true
			combo_label.text = "COMBO x%d! 🔥" % combo_count
			combo_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.9))
		else:
			combo_label.visible = false

func _process(delta: float) -> void:
	if subtitle_panel and subtitle_panel.visible:
		subtitle_timer -= delta
		if subtitle_timer <= 0.0:
			subtitle_panel.visible = false

func _on_score_changed(_new_total: int, added: int) -> void:
	_update_score_display()
	show_floating_points(added)

func _update_score_display() -> void:
	_resolve_nodes()
	if score_label:
		score_label.text = "SCORE: %d" % GameManager.total_score

func show_floating_points(amount: int, col: Color = Color(1.0, 0.9, 0.2)) -> void:
	if not floating_points_container:
		return
	var label := Label.new()
	label.text = "+%d!" % amount
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_shadow_color", Color(0.9, 0.1, 0.6, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = Vector2(randf_range(480, 800), randf_range(160, 240))
	floating_points_container.add_child(label)
	
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.85)
	tween.parallel().tween_property(label, "scale", Vector2(1.3, 1.3), 0.3)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.85)
	tween.tween_callback(label.queue_free)

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

func _on_frame_received(tex: ImageTexture) -> void:
	if video_pip:
		video_pip.texture = tex

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
