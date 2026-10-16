extends Node2D

## WIGGLE WARS! — Level 4: Copycat Chaos 🎭
## Fully Illustrated Theatrical Toy Workshop Stage
## Shinchan animates center stage: Wave Copycat, Body & Dance Imitation, Funny Pose Challenge,
## and Real Microphone Speech Recognition & TTS Repeat!
## Authoritative 45-second timer. Score system completely removed per design requirement.

@onready var hud: CanvasLayer = $HUD
@onready var workshop_canvas: Node2D = $WorldLayer/WorkshopCanvas
@onready var shinchan_sprite: Sprite2D = $WorldLayer/ShinchanSprite
@onready var reaction_meter_bar: ProgressBar = $StageUI/ActionPanel/Margin/VBox/ReactionMeter/ProgressBar
@onready var reaction_label: Label = $StageUI/ActionPanel/Margin/VBox/ReactionMeter/Label
@onready var speak_btn: Button = $StageUI/ActionPanel/Margin/VBox/SpeechControl/SpeakBtn
@onready var speech_status_label: Label = $StageUI/ActionPanel/Margin/VBox/SpeechControl/SpeechStatusLabel
@onready var dialogue_bubble: PanelContainer = $StageUI/DialogueBubble
@onready var dialogue_text: Label = $StageUI/DialogueBubble/Margin/DialogueText

@onready var wave_item: Label = $StageUI/ActionPanel/Margin/VBox/ActionsList/WaveItem
@onready var arms_item: Label = $StageUI/ActionPanel/Margin/VBox/ActionsList/ArmsItem
@onready var dance_item: Label = $StageUI/ActionPanel/Margin/VBox/ActionsList/DanceItem
@onready var hero_item: Label = $StageUI/ActionPanel/Margin/VBox/ActionsList/HeroItem
@onready var body_item: Label = $StageUI/ActionPanel/Margin/VBox/ActionsList/BodyItem
@onready var speech_item: Label = $StageUI/ActionPanel/Margin/VBox/ActionsList/SpeechItem

var character_x: float = 640.0
var character_y: float = 480.0
var char_state: String = "idle" # idle, wave, dance, pose, left_arm, right_arm, hero_pose, crouch, confused, victory, speech
var state_timer: float = 0.0

var audience_hype: float = 15.0
var completed_wave: bool = false
var completed_arms: bool = false
var completed_dance: bool = false
var completed_hero: bool = false
var completed_body: bool = false
var completed_speech: bool = false

# 45-Second Level Timer
var time_remaining: float = 45.0
var level_finished: bool = false
var time_elapsed: float = 0.0
var speech_active: bool = false
var bubble_timer: float = 0.0

func _ready() -> void:
	hud.setup_hud("Level 4: Copycat Chaos 🎭", "Wave, raise arms, dance, strike hero poses, or speak to Shinchan!")
	hud.set_timer(time_remaining)
	
	GestureListener.hand_detected.connect(_on_hand_detected)
	GestureListener.pose_detected.connect(_on_pose_detected)
	GestureListener.speech_result.connect(_on_speech_result)
	GestureListener.speech_status.connect(_on_speech_status)
	
	if workshop_canvas:
		workshop_canvas.draw.connect(_draw_workshop_canvas)
		
	_update_hype_meter(0.0)
	
	AudioManager.play_voice_file("res://assets/audio/shinchan_intro.wav",
		"Yahoo! Welcome to my crazy stage! Wave, dance, strike poses, and speak to me for the next 45 seconds!", 5.5)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 45-Second Level Timer
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		if time_remaining <= 0.0:
			_on_level_timer_complete()
			
	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0 and not level_finished and not speech_active:
			char_state = "idle"

	if bubble_timer > 0.0:
		bubble_timer -= delta
		if bubble_timer <= 0.0 and dialogue_bubble:
			dialogue_bubble.visible = false

	# Animate the authentic Shin Chan standing sprite procedurally
	if shinchan_sprite:
		var base_scale := Vector2(0.42, 0.42)
		var c_pos := Vector2(character_x, character_y)
		var c_rot := 0.0
		var squash := Vector2(1.0, 1.0)

		match char_state:
			"wave":
				c_rot = sin(time_elapsed * 16.0) * 0.14
				c_pos.y += absf(sin(time_elapsed * 12.0)) * -14.0
				squash = Vector2(0.95, 1.05)
			"dance":
				c_pos.x += sin(time_elapsed * 10.0) * 38.0
				c_pos.y += absf(sin(time_elapsed * 10.0)) * -26.0
				c_rot = sin(time_elapsed * 12.0) * 0.22
				squash = Vector2(1.08, 0.92)
			"left_arm":
				c_rot = -0.14
				c_pos.y -= 10.0
				squash = Vector2(0.96, 1.04)
			"right_arm":
				c_rot = 0.14
				c_pos.y -= 10.0
				squash = Vector2(0.96, 1.04)
			"hero_pose":
				c_rot = -0.16
				c_pos.y -= 18.0
				squash = Vector2(1.10, 1.05)
			"pose":
				c_pos.y -= 25.0
				squash = Vector2(0.92, 1.12)
				c_rot = sin(time_elapsed * 6.0) * 0.06
			"crouch":
				c_pos.y += 24.0
				squash = Vector2(1.20, 0.80)
			"lean_left":
				c_rot = -0.22
				c_pos.x -= 25.0
			"lean_right":
				c_rot = 0.22
				c_pos.x += 25.0
			"confused":
				c_rot = sin(time_elapsed * 8.0) * 0.12
				squash = Vector2(0.95, 0.95)
			"speech":
				c_pos.y += sin(time_elapsed * 12.0) * -8.0
				squash = Vector2(1.0 + sin(time_elapsed * 14.0) * 0.06, 1.0 - sin(time_elapsed * 14.0) * 0.06)
			"victory":
				c_pos.y += sin(time_elapsed * 12.0) * -32.0
				c_rot = sin(time_elapsed * 10.0) * 0.15
				squash = Vector2(1.05, 1.05)
			_:
				# Idle gentle breathing bob
				c_pos.y += sin(time_elapsed * 4.0) * 5.0
				squash = Vector2(1.0 + sin(time_elapsed * 4.0) * 0.02, 1.0 - sin(time_elapsed * 4.0) * 0.02)

		shinchan_sprite.position = c_pos
		shinchan_sprite.rotation = c_rot
		shinchan_sprite.scale = base_scale * squash
			
	if workshop_canvas:
		workshop_canvas.queue_redraw()

func _update_hype_meter(add_val: float) -> void:
	audience_hype = clampf(audience_hype + add_val, 0.0, 100.0)
	reaction_meter_bar.value = audience_hype
	reaction_label.text = "AUDIENCE HYPE: %d%% 🔥" % int(audience_hype)

func _show_speech_bubble(text: String, duration: float = 3.5) -> void:
	if dialogue_bubble and dialogue_text:
		dialogue_text.text = text
		dialogue_bubble.visible = true
		bubble_timer = duration

# ------------------------------------------------------------------------------
# ACTION 1: WAVE COPYCAT
# ------------------------------------------------------------------------------
func _on_hand_detected(_pos: Vector2, _swipe: String, is_waving: bool, wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if level_finished or speech_active:
		return

	if is_waving or wave_spd > 0.8:
		char_state = "wave"
		state_timer = 1.1
		completed_wave = true
		wave_item.text = "✅ WAVE: Hand waved wildly!"
		wave_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("👋 Shinchan waves back wildly! Yahoo!")
		_show_speech_bubble("Shinchan: 'Yahoo! Hello best buddy! 👋'", 2.0)

# ------------------------------------------------------------------------------
# ACTION 2 & 4: DANCE & FUNNY POSE COPYCAT
# ------------------------------------------------------------------------------
func _on_pose_detected(gest: String, lean: String, _lean_amt: float, hr: bool, ae: bool, sq: bool, cd: bool) -> void:
	if level_finished or speech_active:
		return

	if cd or gest == "chicken_dance":
		char_state = "dance"
		state_timer = 1.3
		completed_dance = true
		dance_item.text = "✅ DANCE: Grooving like crazy!"
		dance_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(20.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("💃 CRAZY DANCE BATTLE! Shinchan grooves with you!")
		_show_speech_bubble("Shinchan: 'Boogie woogie! Let\\'s dance! 💃'", 2.0)

	elif gest == "hero_pose":
		char_state = "hero_pose"
		state_timer = 1.2
		completed_hero = true
		hero_item.text = "✅ HERO: Action Bastard pose!"
		hero_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(20.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🦸 ACTION BASTARD HERO POSE! Shinchan strikes the hero pose!")
		_show_speech_bubble("Shinchan: 'Action Bastard Beam! Wahaha! 🦸'", 2.2)

	elif gest == "left_arm_raised":
		char_state = "left_arm"
		state_timer = 1.0
		completed_arms = true
		arms_item.text = "✅ ARMS: Raised high in the air!"
		arms_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙋 Left Arm Raised! Shinchan mirrors your left arm!")

	elif gest == "right_arm_raised":
		char_state = "right_arm"
		state_timer = 1.0
		completed_arms = true
		arms_item.text = "✅ ARMS: Raised high in the air!"
		arms_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙋 Right Arm Raised! Shinchan mirrors your right arm!")

	elif hr or gest == "hands_raised":
		char_state = "pose"
		state_timer = 1.1
		completed_arms = true
		arms_item.text = "✅ ARMS: Double Hands Raised!"
		arms_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙌 Double Hand Raise Pose! Action Hero!")

	elif sq or gest == "squat":
		char_state = "crouch"
		state_timer = 1.0
		completed_body = true
		body_item.text = "✅ BODY: Compact crouch executed!"
		body_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🤸 Low Crouch! Shinchan ducks down!")

	elif ae or gest == "arms_extended":
		char_state = "pose"
		state_timer = 1.1
		completed_arms = true
		arms_item.text = "✅ ARMS: Airplane wings extended!"
		arms_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🦅 Airplane Arms Pose! Flying Shinchan!")

	elif lean == "lean_left" or gest == "lean_left" or _lean_amt < -0.06:
		char_state = "lean_left"
		state_timer = 0.9
		completed_body = true
		body_item.text = "✅ BODY: Body tilted left!"
		body_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(10.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("◀️ Leaning Left! Shinchan tilts with you!")

	elif lean == "lean_right" or gest == "lean_right" or _lean_amt > 0.06:
		char_state = "lean_right"
		state_timer = 0.9
		completed_body = true
		body_item.text = "✅ BODY: Body tilted right!"
		body_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(10.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("▶️ Leaning Right! Shinchan tilts with you!")

# ------------------------------------------------------------------------------
# ACTION 3: SPEAK AND REPEAT (Microphone Speech Recognition & TTS)
# ------------------------------------------------------------------------------
func _on_speak_btn_pressed() -> void:
	if level_finished:
		return
	speech_active = true
	char_state = "speech"
	speech_status_label.text = "Listening to microphone... Speak now!"
	hud.set_instruction("🎤 Speak clearly into your mic to talk with Shinchan!")
	_show_speech_bubble("Shinchan: 'I\\'m listening! Speak to me! 🎤'", 3.0)
	GestureListener.request_speech_recognition()

func _on_speech_status(status: String, message: String) -> void:
	if status == "error" or status == "unavailable":
		speech_active = false
		char_state = "confused"
		state_timer = 2.0
		speech_status_label.text = "Microphone tip: %s (Gestures always work!)" % message
		_show_speech_bubble("Shinchan: 'Mic quiet, but we can still dance! 💃'", 2.5)
	else:
		speech_status_label.text = message

func _on_speech_result(success: bool, text: String, audio_file: String) -> void:
	speech_active = false
	if success and text != "":
		completed_speech = true
		speech_item.text = "✅ SPEAK: Speech repeated!"
		speech_item.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_update_hype_meter(25.0)

		# Make Shinchan repeat the exact recognized text!
		char_state = "speech"
		var speak_dur := maxf(3.5, float(text.length()) * 0.14)
		state_timer = speak_dur
		speech_status_label.text = "Shinchan heard & repeated: '%s' 🎤" % text
		hud.set_instruction("Shinchan says: '%s' 🎤" % text)
		_show_speech_bubble("Shinchan: '%s' 🎤" % text, speak_dur)
		AudioManager.play_voice_file(audio_file, "Shinchan: '%s'" % text, speak_dur)
		AudioManager.play_sfx("boing")
	else:
		char_state = "confused"
		state_timer = 1.8
		speech_status_label.text = "Shinchan: 'I didn't catch that! Speak clearly into your mic!'"
		hud.set_instruction("Shinchan is scratching his head! Try speaking again!")
		_show_speech_bubble("Shinchan: 'Say that again, buddy!' 🤔", 2.2)
		AudioManager.play_sfx("chirp")

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	level_finished = true
	char_state = "victory"
	
	hud.set_instruction("TIME'S UP! 🎭 Workshop Rocked! 45s Conquered! 🏆")
	AudioManager.play_sfx("legend_fanfare")
	
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		GameManager.complete_level(4)
		get_tree().change_scene_to_file("res://scenes/level_results.tscn")
	)

# ------------------------------------------------------------------------------
# WORKSHOP ENVIRONMENT & CELEBRATION DRAWING
# ------------------------------------------------------------------------------
func _draw_workshop_canvas() -> void:
	if not workshop_canvas:
		return
		
	# A. Vibrant Theatrical Overhead Stage Spotlights
	var spot_center := Vector2(character_x, character_y - 20.0)
	var spot_pulse := 0.22 + sin(time_elapsed * 3.5) * 0.08
	workshop_canvas.draw_polygon(PackedVector2Array([
		Vector2(180, 0), Vector2(380, 0),
		spot_center + Vector2(160, 180), spot_center + Vector2(-160, 180)
	]), PackedColorArray([Color(1.0, 0.9, 0.4, spot_pulse * 0.6)]))
	
	workshop_canvas.draw_polygon(PackedVector2Array([
		Vector2(1100, 0), Vector2(900, 0),
		spot_center + Vector2(160, 180), spot_center + Vector2(-160, 180)
	]), PackedColorArray([Color(0.4, 0.8, 1.0, spot_pulse * 0.6)]))

	# B. Soft Ground Contact Shadow beneath Shinchan's feet
	workshop_canvas.draw_ellipse(Vector2(character_x, character_y + 175.0), 90.0, 22.0, Color(0.08, 0.06, 0.15, 0.40))

	# C. Party Confetti & Floating Musical Notes
	if audience_hype > 40.0:
		for i in range(8):
			var a := time_elapsed * 2.0 + i * (TAU / 8.0)
			var nx := character_x + cos(a) * (140.0 + i * 15.0)
			var ny := character_y - 60.0 + sin(a) * 55.0
			var col := Color.YELLOW if i % 2 == 0 else Color(1.0, 0.4, 0.7)
			workshop_canvas.draw_circle(Vector2(nx, ny), 4.0, col)
