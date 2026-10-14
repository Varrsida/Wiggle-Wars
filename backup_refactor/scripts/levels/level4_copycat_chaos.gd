extends Node2D

## WIGGLE WARS! — Level 4: Copycat Chaos 🎭
## Fully Illustrated Theatrical Toy Workshop Stage
## Shinchan animates center stage: Wave Copycat, Body & Dance Imitation, Funny Pose Challenge,
## and Real Microphone Speech Recognition & TTS Repeat!
## Exactly 60-second timer. Score system completely removed per design requirement.

@onready var hud: CanvasLayer = $HUD
@onready var workshop_canvas: Node2D = $WorldLayer/WorkshopCanvas
@onready var shinchan_sprite: Sprite2D = $WorldLayer/ShinchanSprite
@onready var reaction_meter_bar: ProgressBar = $StageUI/ReactionMeter/VBox/ProgressBar
@onready var reaction_label: Label = $StageUI/ReactionMeter/VBox/Label
@onready var speak_btn: Button = $StageUI/SpeechControl/SpeakBtn
@onready var speech_status_label: Label = $StageUI/SpeechControl/SpeechStatusLabel

var tex_idle: Texture2D = preload("res://assets/characters/shinchan_hero.png")
var tex_wave: Texture2D = preload("res://assets/characters/shinchan_wave.png")
var tex_left_arm: Texture2D = preload("res://assets/characters/shinchan_left_arm.png")
var tex_right_arm: Texture2D = preload("res://assets/characters/shinchan_right_arm.png")
var tex_both_arms: Texture2D = preload("res://assets/characters/shinchan_both_arms.png")
var tex_crouch: Texture2D = preload("res://assets/characters/shinchan_crouch.png")
var tex_hero_pose: Texture2D = preload("res://assets/characters/shinchan_hero_pose.png")
var tex_tilt: Texture2D = preload("res://assets/characters/shinchan_tilt.png")

var character_x: float = 640.0
var character_y: float = 520.0
var char_state: String = "idle" # idle, wave, dance, pose, left_arm, right_arm, hero_pose, crouch, confused, victory, speech
var state_timer: float = 0.0

var audience_hype: float = 15.0
var completed_wave: bool = false
var completed_dance: bool = false
var completed_speech: bool = false
var completed_pose: bool = false

# 60-Second Level Timer
var time_remaining: float = 60.0
var level_finished: bool = false
var time_elapsed: float = 0.0
var speech_active: bool = false

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
		"Yahoo! Welcome to my crazy stage! Wave, dance, strike poses, and speak to me for the next 60 seconds!", 5.5)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 60-Second Level Timer
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		if time_remaining <= 0.0:
			_on_level_timer_complete()
			
	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0 and not level_finished and not speech_active:
			char_state = "idle"

	# Animate the authentic Shin Chan sprite and dynamically swap pose textures
	if shinchan_sprite:
		var c_pos := Vector2(character_x, character_y)
		var c_rot := 0.0
		var c_scale := Vector2(0.85, 0.85)
		var active_tex: Texture2D = tex_idle

		match char_state:
			"wave":
				active_tex = tex_wave
				c_rot = sin(time_elapsed * 16.0) * 0.14
				c_pos.y += absf(sin(time_elapsed * 12.0)) * -14.0
			"dance":
				active_tex = tex_hero_pose if int(time_elapsed * 6.0) % 2 == 0 else tex_wave
				c_pos.x += sin(time_elapsed * 10.0) * 38.0
				c_pos.y += absf(sin(time_elapsed * 10.0)) * -26.0
				c_rot = sin(time_elapsed * 12.0) * 0.22
				c_scale = Vector2(0.88, 0.82)
			"left_arm":
				active_tex = tex_left_arm
				c_rot = -0.10
				c_pos.y -= 10.0
			"right_arm":
				active_tex = tex_right_arm
				c_rot = 0.10
				c_pos.y -= 10.0
			"hero_pose":
				active_tex = tex_hero_pose
				c_rot = -0.16
				c_pos.y -= 18.0
				c_scale = Vector2(0.90, 0.90)
			"pose":
				active_tex = tex_both_arms
				c_pos.y -= 25.0
				c_scale = Vector2(0.85, 0.90)
				c_rot = sin(time_elapsed * 6.0) * 0.06
			"crouch":
				active_tex = tex_crouch
				c_pos.y += 24.0
				c_scale = Vector2(0.95, 0.75)
			"lean_left":
				active_tex = tex_tilt
				c_rot = -0.22
				c_pos.x -= 25.0
			"lean_right":
				active_tex = tex_tilt
				c_rot = 0.22
				c_pos.x += 25.0
			"confused":
				active_tex = tex_tilt
				c_rot = 0.15
			"victory":
				active_tex = tex_both_arms
				c_pos.y += sin(time_elapsed * 12.0) * -32.0
				c_rot = sin(time_elapsed * 10.0) * 0.15
			_:
				active_tex = tex_idle
				c_pos.y += sin(time_elapsed * 5.0) * 6.0

		if shinchan_sprite.texture != active_tex:
			shinchan_sprite.texture = active_tex
		shinchan_sprite.position = c_pos
		shinchan_sprite.rotation = c_rot
		shinchan_sprite.scale = c_scale
			
	if workshop_canvas:
		workshop_canvas.queue_redraw()

func _update_hype_meter(add_val: float) -> void:
	audience_hype = clampf(audience_hype + add_val, 0.0, 100.0)
	reaction_meter_bar.value = audience_hype
	reaction_label.text = "AUDIENCE HYPE: %d%% 🔥" % int(audience_hype)

# ------------------------------------------------------------------------------
# ACTION 1: WAVE COPYCAT
# ------------------------------------------------------------------------------
func _on_hand_detected(_pos: Vector2, _swipe: String, is_waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if level_finished or speech_active:
		return

	if is_waving:
		char_state = "wave"
		state_timer = 1.1
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("👋 Shinchan waves back wildly! Yahoo!")

# ------------------------------------------------------------------------------
# ACTION 2 & 4: DANCE & FUNNY POSE COPYCAT
# ------------------------------------------------------------------------------
func _on_pose_detected(gest: String, lean: String, _lean_amt: float, hr: bool, ae: bool, sq: bool, cd: bool) -> void:
	if level_finished or speech_active:
		return

	if cd or gest == "chicken_dance":
		char_state = "dance"
		state_timer = 1.3
		_update_hype_meter(20.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("💃 CRAZY DANCE BATTLE! Shinchan grooves with you!")

	elif gest == "hero_pose":
		char_state = "hero_pose"
		state_timer = 1.2
		_update_hype_meter(20.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🦸 ACTION BASTARD HERO POSE! Shinchan strikes the hero pose!")

	elif gest == "left_arm_raised":
		char_state = "left_arm"
		state_timer = 1.0
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙋 Left Arm Raised! Shinchan mirrors your left arm!")

	elif gest == "right_arm_raised":
		char_state = "right_arm"
		state_timer = 1.0
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙋 Right Arm Raised! Shinchan mirrors your right arm!")

	elif hr or gest == "hands_raised":
		char_state = "pose"
		state_timer = 1.1
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙌 Double Hand Raise Pose! Action Hero!")

	elif sq or gest == "squat":
		char_state = "crouch"
		state_timer = 1.0
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🤸 Low Crouch! Shinchan ducks down!")

	elif ae or gest == "arms_extended":
		char_state = "pose"
		state_timer = 1.1
		_update_hype_meter(15.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🦅 Airplane Arms Pose! Flying Shinchan!")

	elif lean == "lean_left" or gest == "lean_left":
		char_state = "lean_left"
		state_timer = 0.9
		_update_hype_meter(10.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("◀️ Leaning Left! Shinchan tilts with you!")

	elif lean == "lean_right" or gest == "lean_right":
		char_state = "lean_right"
		state_timer = 0.9
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
	hud.set_instruction("🎤 Say something funny to Shinchan!")
	GestureListener.request_speech_recognition()

func _on_speech_status(status: String, message: String) -> void:
	if status == "error" or status == "unavailable":
		speech_active = false
		char_state = "confused"
		state_timer = 2.0
		speech_status_label.text = "Microphone tip: %s (Gestures always work!)" % message
	else:
		speech_status_label.text = message

func _on_speech_result(success: bool, text: String, audio_file: String) -> void:
	speech_active = false
	if success and text != "":
		completed_speech = true
		var lower := text.to_lower()
		_update_hype_meter(25.0)

		# Voice command recognition
		if lower.contains("hello") or lower.contains("hi"):
			char_state = "wave"
			state_timer = 2.5
			speech_status_label.text = "Shinchan heard: '%s'! Waving hello back! 👋" % text
			hud.set_instruction("Shinchan: 'HELLO THERE, BEST FRIEND! 👋'")
			AudioManager.play_voice_file("res://assets/audio/shinchan_intro.wav", "Hello there!", 2.5)
			AudioManager.play_sfx("boing")
		elif lower.contains("dance") or lower.contains("party") or lower.contains("music"):
			char_state = "dance"
			state_timer = 3.0
			speech_status_label.text = "Shinchan heard: '%s'! Wild dance party! 💃" % text
			hud.set_instruction("Shinchan: 'DANCE PARTY TIME! 💃'")
			AudioManager.play_sfx("boing")
		elif lower.contains("hero") or lower.contains("action") or lower.contains("super"):
			char_state = "hero_pose"
			state_timer = 2.5
			speech_status_label.text = "Shinchan heard: '%s'! Action Bastard hero pose! 🦸" % text
			hud.set_instruction("Shinchan: 'ACTION BASTARD TO THE RESCUE! 🦸'")
			AudioManager.play_sfx("boing")
		else:
			char_state = "dance"
			state_timer = 2.4
			speech_status_label.text = "Shinchan heard: '%s' 🎤" % text
			hud.set_instruction("Shinchan repeating: '%s' 🎤" % text)
			AudioManager.play_voice_file(audio_file, "Shinchan: '%s'" % text, 4.0)
			AudioManager.play_sfx("boing")
	else:
		char_state = "confused"
		state_timer = 1.8
		speech_status_label.text = "Shinchan: 'I didn't catch that! Speak clearly into your mic!'"
		hud.set_instruction("Shinchan is scratching his head! Try speaking again!")
		AudioManager.play_sfx("boing")

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	level_finished = true
	char_state = "victory"
	
	hud.set_instruction("TIME'S UP! 🎭 Workshop Rocked! 60s Conquered! 🏆")
	AudioManager.play_voice_file("res://assets/audio/shinchan_victory.wav", 
		"Woohoo! You are super awesome!", 4.0)
	AudioManager.play_sfx("legend_fanfare")
	
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_callback(func():
		GameManager.complete_level(4)
		get_tree().change_scene_to_file("res://scenes/level_results.tscn")
	)

# ------------------------------------------------------------------------------
# ILLUSTRATED WORKSHOP ENVIRONMENT & SHINCHAN DRAWING
# ------------------------------------------------------------------------------
func _draw_workshop_canvas() -> void:
	if not workshop_canvas:
		return

	# A. Animated Theatrical Spotlight Beams
	var beam_sway := sin(time_elapsed * 2.2) * 80.0
	workshop_canvas.draw_polygon(PackedVector2Array([
		Vector2(200, 0), Vector2(50 + beam_sway, 620), Vector2(450 + beam_sway, 620)
	]), PackedColorArray([Color(1.0, 0.9, 0.4, 0.12)]))
	workshop_canvas.draw_polygon(PackedVector2Array([
		Vector2(1080, 0), Vector2(830 - beam_sway, 620), Vector2(1230 - beam_sway, 620)
	]), PackedColorArray([Color(0.4, 0.9, 1.0, 0.12)]))

	# B. Stage Footlights along Bottom Edge
	for f in range(16):
		var fx := 80.0 + f * 75.0
		var bulb_col := Color(1.0, 0.9, 0.3) if (f + int(time_elapsed * 4.0)) % 2 == 0 else Color(1.0, 0.3, 0.6)
		workshop_canvas.draw_circle(Vector2(fx, 620), 8.0, bulb_col)

	# C. Ground Shadow for Shinchan
	workshop_canvas.draw_ellipse(Vector2(character_x, 625), 45.0, 14.0, Color(0.1, 0.1, 0.2, 0.4))

	# D. Action Emotes (Confused, Victory)
	var c_pos := Vector2(character_x, character_y)
	if char_state == "confused":
		workshop_canvas.draw_string(ThemeDB.fallback_font, c_pos + Vector2(25, -95), "❓", HORIZONTAL_ALIGNMENT_CENTER, -1, 36, Color.YELLOW)
	elif char_state == "hero_pose":
		# Hero sparkles
		for s in range(4):
			var a := time_elapsed * 4.0 + s * (TAU / 4.0)
			var sp := c_pos + Vector2(cos(a) * 65.0, -40.0 + sin(a) * 35.0)
			workshop_canvas.draw_circle(sp, 5.0, Color(1.0, 0.9, 0.2))
