extends Control

## WIGGLE WARS! — Main Menu
## Animated title, real-time webcam status, neon particle accents, level launch, settings, and credits.

@onready var play_btn: Button = $VBox/Buttons/PlayBtn
@onready var setup_btn: Button = $VBox/Buttons/SetupBtn
@onready var settings_btn: Button = $VBox/Buttons/SettingsBtn
@onready var credits_btn: Button = $VBox/Buttons/CreditsBtn
@onready var exit_btn: Button = $VBox/Buttons/ExitBtn
@onready var title_label: Label = $VBox/Title
@onready var cam_badge_label: Label = $VBox/CamStatusBadge
@onready var settings_modal: PanelContainer = $SettingsModal
@onready var credits_modal: PanelContainer = $CreditsModal

# Settings sliders
@onready var master_slider: HSlider = $SettingsModal/Margin/VBox/MasterRow/Slider
@onready var music_slider: HSlider = $SettingsModal/Margin/VBox/MusicRow/Slider
@onready var sfx_slider: HSlider = $SettingsModal/Margin/VBox/SFXRow/Slider
@onready var voice_slider: HSlider = $SettingsModal/Margin/VBox/VoiceRow/Slider
@onready var mute_chk: CheckBox = $SettingsModal/Margin/VBox/MuteCheck

var float_offset: float = 0.0

func _ready() -> void:
	settings_modal.visible = false
	credits_modal.visible = false
	
	# Connect settings controls
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	voice_slider.value = AudioManager.voice_volume
	mute_chk.button_pressed = AudioManager.is_muted

	GestureListener.tracker_connected.connect(_update_cam_badge)
	GestureListener.tracker_disconnected.connect(_update_cam_badge)
	_update_cam_badge()
	
	AudioManager.play_music_procedural("menu")

func _update_cam_badge() -> void:
	if not cam_badge_label:
		return
	if GestureListener.is_tracker_connected:
		cam_badge_label.text = "● CAMERA ACTIVE & READY (TCP 9999 / 9998) 🟢"
		cam_badge_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45))
	else:
		cam_badge_label.text = "○ TRACKER OFFLINE (Run launch_tracker.bat or press Webcam Setup) 🔴"
		cam_badge_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))

func _process(delta: float) -> void:
	float_offset += delta * 3.0
	if title_label:
		title_label.position.y += sin(float_offset) * 0.4

func _on_play_pressed() -> void:
	AudioManager.play_sfx("chime")
	get_tree().change_scene_to_file("res://scenes/webcam_setup.tscn")

func _on_setup_pressed() -> void:
	AudioManager.play_sfx("chime")
	get_tree().change_scene_to_file("res://scenes/webcam_setup.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("chime")
	settings_modal.visible = true

func _on_close_settings_pressed() -> void:
	AudioManager.play_sfx("chime")
	settings_modal.visible = false

func _on_credits_pressed() -> void:
	AudioManager.play_sfx("chime")
	credits_modal.visible = true

func _on_close_credits_pressed() -> void:
	AudioManager.play_sfx("chime")
	credits_modal.visible = false

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_master_changed(val: float) -> void:
	AudioManager.set_master_volume(val)

func _on_music_changed(val: float) -> void:
	AudioManager.set_music_volume(val)

func _on_sfx_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val)

func _on_voice_changed(val: float) -> void:
	AudioManager.set_voice_volume(val)

func _on_mute_toggled(toggled: bool) -> void:
	AudioManager.set_mute(toggled)
