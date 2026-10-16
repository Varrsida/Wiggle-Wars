extends Node2D

## WIGGLE WARS! — Level 5: Lucky Chaos Wheel 🎡
## Fully Illustrated Carnival Stage & Fairground
## Features EXACTLY SEVEN wheel slices:
## 1. Chocolate Prize 🍫
## 2. Legendary Pen ✨
## 3. Sticker Jackpot 🌈
## 4. Mystery Keychain 🔑
## 5. Mirror Twin 🪞 (reverse imitation challenge)
## 6. Duck Apocalypse 🦆 (giant duck on head & duck chase)
## 7. Chicken Dance Challenge 🐔 (chicken dance party)
## Exactly 60-second session timer. Score system completely removed per design requirement.

@onready var hud: CanvasLayer = $HUD
@onready var carnival_canvas: Node2D = $WorldLayer/CarnivalCanvas
@onready var spin_btn: Button = $StageUI/SpinBtn
@onready var event_overlay: CanvasLayer = $EventOverlay
@onready var event_title: Label = $EventOverlay/Panel/VBox/EventTitle
@onready var event_desc: Label = $EventOverlay/Panel/VBox/EventDesc
@onready var ducks_container: Node2D = $WorldLayer/DucksContainer

const SLICES: Array[String] = [
	"Lucky Pen 🖊️",
	"Chocolate Surprise 🍫",
	"Sticker Blast 🌈",
	"Keychain Quest 🔑",
	"Funny Actions 😂",
	"Chicken Dance 🐔",
	"Robot Dance 🤖"
]

const SLICE_COLORS: Array[Color] = [
	Color(0.85, 0.45, 0.20), # Chocolate Brown/Caramel
	Color(0.95, 0.35, 0.80), # Rainbow Pink/Magenta
	Color(0.20, 0.75, 0.95), # Electric Blue/Cyan
	Color(1.00, 0.85, 0.15), # Gold/Yellow
	Color(1.00, 0.50, 0.15), # Orange
	Color(0.55, 0.85, 0.95), # Ice Cyan
	Color(0.40, 0.95, 0.45)  # Lime Green
]

var wheel_angle: float = 0.0
var wheel_speed: float = 0.0
var is_spinning: bool = false
var target_slice_idx: int = -1
var target_angle: float = 0.0
var spin_progress: float = 0.0

var active_challenge: String = ""
var challenge_timer: float = 0.0

# 45-Second Level Timer
var time_remaining: float = 45.0
var level_finished: bool = false
var time_elapsed: float = 0.0

# Touch-to-spin hand tracking & feedback
var can_touch_spin: bool = true
var touch_feedback_time: float = 0.0
var touch_pos: Vector2 = Vector2.ZERO

# Decorative carnival lights & flags
var bunting_flags: Array[Dictionary] = []

func _ready() -> void:
	hud.setup_hud("Level 5: Lucky Chaos Wheel 🎡", "Touch the wheel with your hand or press 'SPIN THE WHEEL'!")
	hud.set_timer(time_remaining)
	event_overlay.visible = false
	
	GestureListener.pose_detected.connect(_on_pose_detected)
	GestureListener.hand_detected.connect(_on_hand_detected)
	
	if carnival_canvas:
		carnival_canvas.draw.connect(_draw_carnival_canvas)
		
	_init_carnival_decorations()
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level5.wav",
		"Step right up to the Lucky Chaos Wheel! Spin for wild prizes and hilarious surprises for the next 45 seconds!", 6.0)

func _init_carnival_decorations() -> void:
	bunting_flags.clear()
	for i in range(18):
		bunting_flags.append({
			"x": i * 72.0 + 36.0,
			"color": Color.from_hsv(float(i) / 18.0, 0.85, 1.0)
		})

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 60-Second Level Timer
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		if time_remaining <= 0.0:
			_on_level_timer_complete()
	
	if is_spinning:
		_process_wheel_spin(delta)
	
	if active_challenge != "":
		_process_challenge(delta)
		
	if touch_feedback_time > 0.0:
		touch_feedback_time -= delta

	if carnival_canvas:
		carnival_canvas.queue_redraw()

func _on_hand_detected(cursor_pos: Vector2, swipe: String, _waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if level_finished or is_spinning or active_challenge != "":
		return

	var screen_pos := Vector2(cursor_pos.x * 1280.0, cursor_pos.y * 720.0)
	var center := Vector2(640.0, 310.0)
	var radius := 195.0
	var dist := screen_pos.distance_to(center)

	# Detect hand touching or swiping wheel
	if dist <= radius or (dist <= radius + 50.0 and swipe != "none"):
		if can_touch_spin:
			can_touch_spin = false
			touch_pos = screen_pos
			touch_feedback_time = 0.85
			AudioManager.play_sfx("swish")
			_on_spin_btn_pressed()
	elif dist > radius + 70.0:
		can_touch_spin = true

func _on_spin_btn_pressed() -> void:
	if is_spinning or active_challenge != "" or level_finished:
		return
	
	spin_btn.disabled = true
	# Pick random outcome among exactly 7 slices
	target_slice_idx = randi() % 7
	GameManager.level5_wheel_outcome = SLICES[target_slice_idx]
	
	# Exactly 7 slices: each slice is TAU / 7 (~51.43 degrees)
	# Top pointer is at 3*PI/2 (270 deg)
	var slice_arc := TAU / 7.0
	var slice_center := target_slice_idx * slice_arc + (slice_arc * 0.5)
	var pointer_offset := 3.0 * PI / 2.0
	target_angle = (TAU * 5.0) + (pointer_offset - slice_center)
	
	wheel_speed = 18.0
	spin_progress = 0.0
	is_spinning = true
	AudioManager.play_sfx("wheel_click")
	hud.set_instruction("Wheel is spinning... What will you win?")

func _process_wheel_spin(delta: float) -> void:
	spin_progress += delta * 0.28 # spins for ~3.5s
	if spin_progress < 1.0:
		var t := 1.0 - pow(1.0 - spin_progress, 3.0)
		wheel_angle = lerpf(0.0, target_angle, t)
		if fmod(wheel_angle, TAU / 7.0) < 0.2:
			AudioManager.play_sfx("wheel_click")
	else:
		wheel_angle = target_angle
		is_spinning = false
		_on_wheel_stopped()

func _on_wheel_stopped() -> void:
	AudioManager.play_sfx("wheel_win")
	hud.set_instruction("Result: %s!" % SLICES[target_slice_idx])
	GameManager.level5_wheel_completed = true
	
	match target_slice_idx:
		0: _outcome_lucky_pen()
		1: _outcome_chocolate_surprise()
		2: _outcome_sticker_blast()
		3: _outcome_keychain_quest()
		4: _outcome_funny_actions()
		5: _outcome_chicken_dance()
		6: _outcome_robot_dance()

# ------------------------------------------------------------------------------
# EXACT 7 SPECIFIED WHEEL OUTCOMES
# ------------------------------------------------------------------------------
func _outcome_lucky_pen() -> void:
	active_challenge = "pen"
	challenge_timer = 4.0
	AudioManager.play_sfx("crystal")
	_show_event_modal("LUCKY PEN 🖊️", "Legendary whimsical pen awarded! Ready to write your carnival legend!")

func _outcome_chocolate_surprise() -> void:
	active_challenge = "chocolate"
	challenge_timer = 4.0
	AudioManager.play_sfx("combo")
	_show_event_modal("CHOCOLATE SURPRISE 🍫", "Delicious sweet chocolate prize awarded! Savor your carnival treat!")

func _outcome_sticker_blast() -> void:
	active_challenge = "stickers"
	challenge_timer = 4.0
	AudioManager.play_sfx("chime")
	_show_event_modal("STICKER BLAST 🌈", "Rainbow sticker blast unlocked! Sparkling colorful carnival stickers burst!")

func _outcome_keychain_quest() -> void:
	active_challenge = "keychain"
	challenge_timer = 4.0
	AudioManager.play_sfx("legend_fanfare")
	_show_event_modal("KEYCHAIN QUEST 🔑", "Adorable lucky carnival keychain won! A charming keepsake for your adventure!")

func _outcome_funny_actions() -> void:
	active_challenge = "funny_actions"
	challenge_timer = 8.0
	AudioManager.play_sfx("boing")
	_show_event_modal("FUNNY ACTIONS 😂", "Strike silly poses, tilt your head, or make funny faces! (8 Seconds)")

func _outcome_chicken_dance() -> void:
	active_challenge = "chicken_dance"
	challenge_timer = 10.0
	AudioManager.play_sfx("quack")
	_show_event_modal("CHICKEN DANCE 🐔", "Flap your arms like chicken wings, wiggle your body, and dance for 10 seconds!")
	_spawn_ducks()

func _outcome_robot_dance() -> void:
	active_challenge = "robot_dance"
	challenge_timer = 10.0
	AudioManager.play_sfx("boing")
	_show_event_modal("ROBOT DANCE 🤖", "Move like a robot with stiff arms, robotic steps, and robotic poses for 10 seconds!")

func _show_event_modal(t: String, d: String) -> void:
	event_title.text = t
	event_desc.text = d
	event_overlay.visible = true

func _spawn_ducks() -> void:
	for i in range(14):
		var duck := Node2D.new()
		duck.position = Vector2(randf_range(80, 1200), randf_range(280, 640))
		ducks_container.add_child(duck)
		
		var tw := create_tween().set_loops(4)
		tw.tween_property(duck, "position:x", duck.position.x + randf_range(-160, 160), 1.2)
		tw.tween_callback(func(): AudioManager.play_sfx("quack"))

func _process_challenge(delta: float) -> void:
	challenge_timer -= delta
	event_desc.text = "Time Remaining: %.1f seconds!" % maxf(0.0, challenge_timer)
	
	if challenge_timer <= 0.0:
		active_challenge = ""
		AudioManager.play_sfx("combo")
		event_title.text = "CHALLENGE PASSED! 🎉"
		event_desc.text = "Spectacular carnival performance! The crowd cheers!"
		_finish_event_after(2.0)

func _on_pose_detected(gest: String, lean: String, _amt: float, hr: bool, ae: bool, sq: bool, cd: bool) -> void:
	if active_challenge == "chicken_dance" and (cd or gest == "chicken_dance"):
		AudioManager.play_sfx("quack")
		hud.set_instruction("🐔 Chicken dance motion recognized! Flapping on beat!")
	elif active_challenge == "robot_dance" and (ae or hr or gest in ["arms_extended", "hero_pose"]):
		AudioManager.play_sfx("boing")
		hud.set_instruction("🤖 Stiff robot moves recognized! Beep boop!")
	elif active_challenge == "funny_actions" and (sq or lean != "neutral" or gest != "neutral"):
		AudioManager.play_sfx("boing")
		hud.set_instruction("😂 Silly carnival pose recognized! Wahaha!")

func _finish_event_after(sec: float) -> void:
	var tw := create_tween()
	tw.tween_interval(sec)
	tw.tween_callback(func():
		event_overlay.visible = false
		spin_btn.disabled = false
	)

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	level_finished = true
	event_overlay.visible = false
	
	hud.set_instruction("TIME'S UP! 🎡 Carnival Conquered! 60s Session Complete! 🏆")
	AudioManager.play_sfx("combo")
	
	GameManager.level5_wheel_completed = true
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		GameManager.complete_level(5)
		get_tree().change_scene_to_file("res://scenes/level_results.tscn")
	)

# ------------------------------------------------------------------------------
# ILLUSTRATED CARNIVAL FAIRGROUND & 7-SLICE WHEEL DRAWING
# ------------------------------------------------------------------------------
func _draw_carnival_canvas() -> void:
	if not carnival_canvas:
		return

	# A. Festive Bunting Flags across Top
	for f in bunting_flags:
		var fx: float = f["x"]
		var f_col: Color = f["color"]
		carnival_canvas.draw_polygon(PackedVector2Array([
			Vector2(fx - 24, 75), Vector2(fx + 24, 75), Vector2(fx, 115)
		]), PackedColorArray([f_col]))
	carnival_canvas.draw_line(Vector2(0, 75), Vector2(1280, 75), Color(0.8, 0.7, 0.3), 3.0)

	# C. Carnival Stage Platform at Bottom
	carnival_canvas.draw_rect(Rect2(0, 580, 1280, 140), Color(0.42, 0.24, 0.16))
	carnival_canvas.draw_line(Vector2(0, 580), Vector2(1280, 580), Color(1.0, 0.82, 0.25), 6.0)
	# Glowing carnival bulb string
	for b in range(20):
		var bx := 32.0 + b * 64.0
		var bulb_col := Color(1.0, 0.9, 0.3) if (b + int(time_elapsed * 4.0)) % 2 == 0 else Color(0.2, 0.95, 1.0)
		carnival_canvas.draw_circle(Vector2(bx, 580), 7.0, bulb_col)

	# D. THE LUCKY CHAOS WHEEL (EXACTLY 7 SLICES!)
	var center := Vector2(640.0, 310.0)
	var radius := 195.0
	var slice_arc := TAU / 7.0
	
	# Draw Exactly 7 Slices
	for i in range(7):
		var start_a := wheel_angle + (i * slice_arc)
		var end_a := start_a + slice_arc
		var pts := PackedVector2Array([center])
		for step in range(16):
			var a := lerpf(start_a, end_a, float(step) / 15.0)
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		carnival_canvas.draw_polygon(pts, PackedColorArray([SLICE_COLORS[i]]))
		# Slice divider lines
		carnival_canvas.draw_line(center, center + Vector2(cos(start_a), sin(start_a)) * radius, Color.WHITE, 2.5)
		
		# Slice Icon Badge
		var mid_a := start_a + slice_arc * 0.5
		var icon_pos := center + Vector2(cos(mid_a), sin(mid_a)) * (radius * 0.66)
		carnival_canvas.draw_circle(icon_pos, 16.0, Color(1.0, 1.0, 1.0, 0.92))
		carnival_canvas.draw_arc(icon_pos, 16.0, 0, TAU, 16, Color(0.2, 0.2, 0.2, 0.6), 1.5)
		var short_icons := ["🖊️", "🍫", "🌈", "🔑", "😂", "🐔", "🤖"]
		carnival_canvas.draw_string(ThemeDB.fallback_font, icon_pos + Vector2(-9, 5), short_icons[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.BLACK)

	# Wheel Rim with Gold Studs
	carnival_canvas.draw_arc(center, radius, 0.0, TAU, 64, Color(1.0, 0.85, 0.25), 14.0)
	for stud in range(14):
		var sa := wheel_angle + stud * (TAU / 14.0)
		carnival_canvas.draw_circle(center + Vector2(cos(sa), sin(sa)) * radius, 5.0, Color.WHITE)
		
	# Wheel Center Hub
	carnival_canvas.draw_circle(center, 30.0, Color(0.15, 0.18, 0.32))
	carnival_canvas.draw_circle(center, 14.0, Color.GOLD)

	# Top Pointer Indicator (Points exactly to winning top slice)
	var pointer_top := center + Vector2(0, -radius - 12.0)
	carnival_canvas.draw_polygon(PackedVector2Array([
		pointer_top + Vector2(0, 36),
		pointer_top + Vector2(-16, -10),
		pointer_top + Vector2(16, -10)
	]), PackedColorArray([Color(1.0, 0.2, 0.2)]))
	carnival_canvas.draw_circle(pointer_top + Vector2(0, -10), 9.0, Color.GOLD)

	# E. Duck Overlay for Chicken / Duck Celebrations
	if active_challenge == "chicken_dance":
		var giant_duck_pos := Vector2(640.0, 190.0)
		carnival_canvas.draw_circle(giant_duck_pos, 45.0, Color(1.0, 0.88, 0.1))
		carnival_canvas.draw_circle(giant_duck_pos + Vector2(24, -25), 26.0, Color(1.0, 0.88, 0.1))
		carnival_canvas.draw_circle(giant_duck_pos + Vector2(32, -30), 4.5, Color.BLACK)
		carnival_canvas.draw_polygon(PackedVector2Array([
			giant_duck_pos + Vector2(45, -25), giant_duck_pos + Vector2(65, -20), giant_duck_pos + Vector2(45, -15)
		]), PackedColorArray([Color(1.0, 0.5, 0.1)]))

	# F. Touch-to-Spin Visual Feedback Ripple
	if touch_feedback_time > 0.0:
		var ripple_t := 1.0 - (touch_feedback_time / 0.85)
		var ripple_r := ripple_t * 65.0 + 20.0
		var alpha := clampf(touch_feedback_time / 0.85, 0.0, 1.0)
		carnival_canvas.draw_circle(touch_pos, ripple_r, Color(1.0, 0.9, 0.3, alpha * 0.35))
		carnival_canvas.draw_arc(touch_pos, ripple_r, 0.0, TAU, 32, Color(0.2, 0.95, 1.0, alpha), 4.0)
		for s in range(6):
			var sa := s * (TAU / 6.0) + ripple_t * 3.0
			var sp := touch_pos + Vector2(cos(sa), sin(sa)) * (ripple_r + 15.0)
			carnival_canvas.draw_circle(sp, 4.0, Color(1.0, 1.0, 0.6, alpha))
