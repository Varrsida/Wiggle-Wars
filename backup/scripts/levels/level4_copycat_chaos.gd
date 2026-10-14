extends Node2D

## WIGGLE WARS! — Level 4: Copycat Chaos 🎭
## Shinchan's Crazy Toy Workshop
## Features Wave Copycat, Body & Dance Imitation, Funny Pose Challenge,
## and Real Microphone Speech Recognition & TTS Repeat!

@onready var hud: CanvasLayer = $HUD
@onready var character_node: Node2D = $Character
@onready var reaction_meter_bar: ProgressBar = $StageUI/ReactionMeter/ProgressBar
@onready var reaction_label: Label = $StageUI/ReactionMeter/Label
@onready var speak_btn: Button = $StageUI/SpeechControl/SpeakBtn
@onready var speech_status_label: Label = $StageUI/SpeechControl/SpeechStatusLabel

var character_x: float = 640.0
var character_y: float = 520.0
var char_state: String = "idle" # idle, wave, dance, pose, confused, victory
var state_timer: float = 0.0

var reaction_score: float = 0.0
var completed_wave: bool = false
var completed_dance: bool = false
var completed_speech: bool = false
var completed_pose: bool = false
var level_finished: bool = false

var time_elapsed: float = 0.0
var speech_active: bool = false

func _ready() -> void:
	hud.setup_hud("Level 4: Copycat Chaos 🎭", "Wave, dance, strike funny poses, or speak to Shinchan!")
	
	GestureListener.hand_detected.connect(_on_hand_detected)
	GestureListener.pose_detected.connect(_on_pose_detected)
	GestureListener.speech_result.connect(_on_speech_result)
	GestureListener.speech_status.connect(_on_speech_status)
	
	AudioManager.play_voice_file("res://assets/audio/shinchan_intro.wav",
		"Yahoo! Welcome to my crazy workshop! Wave, dance, and let's play!", 5.0)

	_update_meter(0.0)

func _process(delta: float) -> void:
	time_elapsed += delta
	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0 and not level_finished:
			char_state = "idle"
	queue_redraw()

func _update_meter(add_val: float) -> void:
	reaction_score = clampf(reaction_score + add_val, 0.0, 100.0)
	reaction_meter_bar.value = reaction_score
	reaction_label.text = "REACTION METER: %d%%" % int(reaction_score)
	
	if reaction_score >= 100.0 and not level_finished:
		_finish_level()

func _finish_level() -> void:
	level_finished = true
	char_state = "victory"
	hud.set_instruction("WORKSHOP ROCKED! Shinchan is laughing with joy!")
	AudioManager.play_voice_file("res://assets/audio/shinchan_victory.wav", 
		"Woohoo! You are super awesome!", 4.0)
	AudioManager.play_sfx("legend_fanfare")
	
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		GameManager.complete_level(4)
		get_tree().change_scene_to_file("res://scenes/level_results.tscn")
	)

# ------------------------------------------------------------------------------
# ACTION 1: WAVE COPYCAT
# ------------------------------------------------------------------------------
func _on_hand_detected(_pos: Vector2, _swipe: String, is_waving: bool, wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if level_finished or char_state == "speech":
		return

	if is_waving:
		char_state = "wave"
		state_timer = 1.0
		if not completed_wave or randf() < 0.2:
			completed_wave = true
			GameManager.add_score(15)
			_update_meter(25.0)
			AudioManager.play_sfx("boing")
			hud.set_instruction("👋 Shinchan waves back wildly! (+15)")

# ------------------------------------------------------------------------------
# ACTION 2 & 4: DANCE & FUNNY POSE COPYCAT
# ------------------------------------------------------------------------------
func _on_pose_detected(gest: String, lean: String, _lean_amt: float, hr: bool, ae: bool, _sq: bool, cd: bool) -> void:
	if level_finished or char_state == "speech":
		return

	if cd or gest == "chicken_dance":
		char_state = "dance"
		state_timer = 1.2
		if not completed_dance:
			completed_dance = true
			GameManager.add_score(20)
			_update_meter(30.0)
			AudioManager.play_sfx("boing")
			AudioManager.play_voice_file("res://assets/audio/shinchan_dance.wav",
				"Look at my funny dance! Can you do this?", 3.5)
			hud.set_instruction("💃 CRAZY DANCE BATTLE! Shinchan grooves! (+20)")

	elif hr or gest == "hands_raised":
		char_state = "pose"
		state_timer = 1.0
		GameManager.add_score(15)
		_update_meter(20.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🙌 Double Hand Raise Pose! (+15)")

	elif ae or gest == "arms_extended":
		char_state = "pose"
		state_timer = 1.0
		GameManager.add_score(15)
		_update_meter(20.0)
		AudioManager.play_sfx("boing")
		hud.set_instruction("🦅 Airplane Arms Pose! (+15)")

	elif lean != "neutral":
		char_state = "dance"
		state_timer = 0.8
		_update_meter(5.0)

# ------------------------------------------------------------------------------
# ACTION 3: SPEAK AND REPEAT (Real Microphone, SpeechRecognition & TTS)
# ------------------------------------------------------------------------------
func _on_speak_btn_pressed() -> void:
	speech_active = true
	char_state = "speech"
	speech_status_label.text = "Listening to microphone... Speak now!"
	hud.set_instruction("🎤 Say something funny to Shinchan!")
	GestureListener.request_speech_recognition()

func _on_speech_status(_status: String, message: String) -> void:
	speech_status_label.text = message

func _on_speech_result(success: bool, text: String, audio_file: String) -> void:
	speech_active = false
	if success and text != "":
		completed_speech = true
		char_state = "dance"
		state_timer = 2.0
		GameManager.add_score(25)
		_update_meter(35.0)
		
		speech_status_label.text = "Shinchan heard: '%s'!" % text
		hud.set_instruction("Shinchan repeating: '%s' (+25!)" % text)
		
		# Play synthesized repeat
		AudioManager.play_voice_file(audio_file, "Shinchan: '%s'" % text, 4.0)
		AudioManager.play_sfx("boing")
	else:
		char_state = "confused"
		state_timer = 1.8
		speech_status_label.text = "Shinchan: 'I didn't catch that! Try again!'"
		hud.set_instruction("Shinchan is scratching his head! Try speaking again!")
		AudioManager.play_sfx("boing")

func _draw() -> void:
	# Draw Animated Stage Lights
	var light_col := Color(1.0, 0.9, 0.4, 0.12)
	draw_polygon(PackedVector2Array([
		Vector2(200, 0), Vector2(100, 720), Vector2(500, 720)
	]), PackedColorArray([light_col]))
	draw_polygon(PackedVector2Array([
		Vector2(1080, 0), Vector2(780, 720), Vector2(1180, 720)
	]), PackedColorArray([light_col]))

	# Character Procedural Animation
	var c_pos := Vector2(character_x, character_y)
	var wobble := sin(time_elapsed * 8.0) * 0.1
	var arm_l_angle := 0.2
	var arm_r_angle := -0.2

	match char_state:
		"wave":
			arm_r_angle = sin(time_elapsed * 16.0) * 0.8 - 1.2
			wobble = sin(time_elapsed * 12.0) * 0.25
		"dance":
			c_pos.x += sin(time_elapsed * 10.0) * 35.0
			c_pos.y += abs(sin(time_elapsed * 10.0)) * -25.0
			arm_l_angle = sin(time_elapsed * 10.0) * 1.2
			arm_r_angle = -cos(time_elapsed * 10.0) * 1.2
		"pose":
			c_pos.y -= 30.0
			arm_l_angle = -1.8
			arm_r_angle = 1.8
		"confused":
			# Comic question mark over head
			draw_string(ThemeDB.fallback_font, c_pos + Vector2(25, -90), "❓", HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.YELLOW)
		"victory":
			c_pos.y += sin(time_elapsed * 12.0) * -40.0
			arm_l_angle = -2.2
			arm_r_angle = 2.2

	# 1. Yellow Shorts
	draw_rect(Rect2(c_pos + Vector2(-30, 20), Vector2(60, 45)), Color(1.0, 0.9, 0.1))
	# Legs
	draw_rect(Rect2(c_pos + Vector2(-25, 65), Vector2(18, 30)), Color(1.0, 0.8, 0.65))
	draw_rect(Rect2(c_pos + Vector2(7, 65), Vector2(18, 30)), Color(1.0, 0.8, 0.65))
	# Shoes
	draw_ellipse(c_pos + Vector2(-16, 95), 14.0, 8.0, Color(0.9, 0.85, 0.2))
	draw_ellipse(c_pos + Vector2(16, 95), 14.0, 8.0, Color(0.9, 0.85, 0.2))

	# 2. Red Shirt
	draw_polygon(PackedVector2Array([
		c_pos + Vector2(-36, 25), c_pos + Vector2(36, 25),
		c_pos + Vector2(28, -35), c_pos + Vector2(-28, -35)
	]), PackedColorArray([Color(0.95, 0.15, 0.15)]))

	# 3. Arms
	var l_hand := c_pos + Vector2(-32, -15) + Vector2(cos(arm_l_angle + PI/2), sin(arm_l_angle + PI/2)) * 40.0
	var r_hand := c_pos + Vector2(32, -15) + Vector2(cos(arm_r_angle + PI/2), sin(arm_r_angle + PI/2)) * 40.0
	draw_line(c_pos + Vector2(-28, -25), l_hand, Color(1.0, 0.8, 0.65), 14.0)
	draw_line(c_pos + Vector2(28, -25), r_hand, Color(1.0, 0.8, 0.65), 14.0)

	# 4. Shinchan's Distinctive Cheeky Head
	var head_pos := c_pos + Vector2(0, -65)
	# Chubby round face
	draw_ellipse(head_pos, 42.0, 36.0, Color(1.0, 0.82, 0.68))
	draw_ellipse(head_pos + Vector2(24, 8), 18.0, 16.0, Color(1.0, 0.82, 0.68)) # Cheek

	# 5. Cropped Black Hair
	draw_polygon(PackedVector2Array([
		head_pos + Vector2(-42, -5), head_pos + Vector2(-38, -36),
		head_pos + Vector2(0, -42), head_pos + Vector2(38, -36),
		head_pos + Vector2(40, -10), head_pos + Vector2(28, -20),
		head_pos + Vector2(-10, -25)
	]), PackedColorArray([Color(0.1, 0.1, 0.12)]))

	# 6. Thick Eyebrows (Signature feature)
	draw_line(head_pos + Vector2(-26, -16), head_pos + Vector2(-6, -20), Color.BLACK, 7.0)
	draw_line(head_pos + Vector2(10, -20), head_pos + Vector2(30, -16), Color.BLACK, 7.0)

	# 7. Big Cheeky Eyes
	draw_ellipse(head_pos + Vector2(-16, -6), 9.0, 11.0, Color.BLACK)
	draw_ellipse(head_pos + Vector2(20, -6), 9.0, 11.0, Color.BLACK)
	draw_circle(head_pos + Vector2(-18, -8), 4.0, Color.WHITE)
	draw_circle(head_pos + Vector2(18, -8), 4.0, Color.WHITE)

	# 8. Mischievous Grin
	draw_arc(head_pos + Vector2(4, 12), 16.0, 0.1, 2.9, 16, Color(0.8, 0.2, 0.2), 4.0)
