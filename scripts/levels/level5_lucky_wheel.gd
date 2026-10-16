extends Node2D

## WIGGLE WARS! — Level 5: Lucky Chaos Wheel 🎡
## Fully Illustrated Carnival Fairground with the Official Lucky Chaos Wheel
## Features EXACTLY SEVEN challenge outcomes:
## 1. Lucky Pen 🖊️
## 2. Chocolate Surprise 🍫
## 3. Sticker Blast 🌈
## 4. Keychain Quest 🔑
## 5. Funny Actions 😂
## 6. Chicken Dance 🐔
## 7. Robot Dance 🤖
## Full 45-second round state machine:
##   0–5s: Intro & Wheel Spin
##   5–25s: 20-Second Challenge & Reward Phase (Synchronized countdown)
##   25–35s: Celebratory Result & Reward Reveal
##   35–45s: Grand Carnival Finale & Transition Countdown

@onready var hud: CanvasLayer = $HUD
@onready var carnival_canvas: Node2D = $WorldLayer/CarnivalCanvas
@onready var wheel_anchor: Node2D = $WorldLayer/WheelAnchor
@onready var wheel_disc: Sprite2D = $WorldLayer/WheelAnchor/WheelDisc
@onready var pointer_sprite: Sprite2D = $WorldLayer/PointerSprite
@onready var ducks_container: Node2D = $WorldLayer/DucksContainer

@onready var spin_btn: Button = $StageUI/SpinBtn
@onready var event_overlay: CanvasLayer = $EventOverlay
@onready var event_title: Label = $EventOverlay/Panel/Margin/VBox/EventTitle
@onready var outcome_icon: TextureRect = $EventOverlay/Panel/Margin/VBox/OutcomeIcon
@onready var event_desc: Label = $EventOverlay/Panel/Margin/VBox/EventDesc
@onready var countdown_label: Label = $EventOverlay/Panel/Margin/VBox/CountdownLabel

const SLICES: Array[String] = [
	"Lucky Pen 🖊️",
	"Chocolate Surprise 🍫",
	"Sticker Blast 🌈",
	"Keychain Quest 🔑",
	"Funny Actions 😂",
	"Chicken Dance 🐔",
	"Robot Dance 🤖"
]

var outcome_textures: Dictionary = {
	0: preload("res://assets/sprites/outcome_pen.png"),
	1: preload("res://assets/sprites/outcome_chocolate.png"),
	2: preload("res://assets/sprites/outcome_sticker_blast.png"),
	3: preload("res://assets/sprites/outcome_keychain.png"),
	4: preload("res://assets/sprites/outcome_funny_actions.png"),
	5: preload("res://assets/sprites/outcome_chicken_dance.png"),
	6: preload("res://assets/sprites/outcome_robot_dance.png")
}

# Round Phases (Exactly 30-Second Master Timeline)
enum Phase {
	INTRO_SPIN,        # 0.0 - 4.0s (Smooth wheel spin & selection)
	CHALLENGE_PHASE,   # 4.0 - 19.0s (Selected challenge / activity)
	CELEBRATION_PHASE, # 19.0 - 24.0s (Reward / result reveal)
	FINALE_PHASE       # 24.0 - 30.0s (Celebration & transition preparation)
}

var current_phase: Phase = Phase.INTRO_SPIN
var time_elapsed: float = 0.0
const TOTAL_ROUND_TIME: float = 30.0
var level_finished: bool = false

# Wheel Spin Variables
var wheel_angle: float = 0.0
var is_spinning: bool = false
var target_slice_idx: int = 0
var target_angle: float = 0.0
var spin_time_elapsed: float = 0.0
var spin_duration: float = 3.0

# Hand Interaction Debounce
var can_touch_spin: bool = true
var touch_feedback_time: float = 0.0
var touch_pos: Vector2 = Vector2.ZERO
var last_touch_time: float = -10.0

# Active challenge tracking
var active_challenge_name: String = ""
var pose_feedback_timer: float = 0.0

# Decorative carnival bunting flags
var bunting_flags: Array[Dictionary] = []

func _ready() -> void:
	hud.setup_hud("Level 5: Lucky Chaos Wheel 🎡", "Touch the wheel with your hand or click 'SPIN THE WHEEL'!")
	hud.set_timer(TOTAL_ROUND_TIME)
	event_overlay.visible = false
	
	GestureListener.pose_detected.connect(_on_pose_detected)
	GestureListener.hand_detected.connect(_on_hand_detected)
	GestureListener.face_detected.connect(_on_face_detected)
	
	if carnival_canvas:
		carnival_canvas.draw.connect(_draw_carnival_canvas)
		
	_init_carnival_decorations()
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level5.wav",
		"Step right up to the Lucky Chaos Wheel! Spin for wild prizes and hilarious surprises for the next 30 seconds!", 5.0)

func _init_carnival_decorations() -> void:
	bunting_flags.clear()
	for i in range(18):
		bunting_flags.append({
			"x": i * 72.0 + 36.0,
			"color": Color.from_hsv(float(i) / 18.0, 0.85, 1.0)
		})

func _process(delta: float) -> void:
	if level_finished:
		return

	time_elapsed += delta
	var time_remaining := maxf(0.0, TOTAL_ROUND_TIME - time_elapsed)
	hud.set_timer(time_remaining)

	# Master State Machine (Single source of truth: 30-Second Total Session)
	if time_elapsed < 4.0:
		_process_intro_spin_phase(delta)
	elif time_elapsed < 19.0:
		_process_challenge_phase(delta)
	elif time_elapsed < 24.0:
		_process_celebration_phase(delta)
	elif time_elapsed < TOTAL_ROUND_TIME:
		_process_finale_phase(delta)
	else:
		_on_level_timer_complete()

	if touch_feedback_time > 0.0:
		touch_feedback_time -= delta

	if pose_feedback_timer > 0.0:
		pose_feedback_timer -= delta

	if carnival_canvas:
		carnival_canvas.queue_redraw()

# ------------------------------------------------------------------------------
# PHASE 1: INTRO & SPIN (0.0 to 4.0s)
# ------------------------------------------------------------------------------
func _process_intro_spin_phase(delta: float) -> void:
	current_phase = Phase.INTRO_SPIN
	
	# If player hasn't spun after 0.8s, auto-spin so spin completes smoothly by 3.8s
	if not is_spinning and time_elapsed >= 0.8 and target_slice_idx == 0 and wheel_angle == 0.0:
		_start_wheel_spin()

	if is_spinning:
		spin_time_elapsed += delta
		var t := clampf(spin_time_elapsed / spin_duration, 0.0, 1.0)
		# Smooth cubic ease out
		var ease_t := 1.0 - pow(1.0 - t, 3.0)
		wheel_angle = lerpf(0.0, target_angle, ease_t)
		if wheel_disc:
			wheel_disc.rotation = wheel_angle

		if pointer_sprite:
			pointer_sprite.rotation = sin(spin_time_elapsed * 32.0 * (1.0 - t)) * 0.12

		# Click audio ticks
		if fmod(wheel_angle, TAU / 7.0) < 0.2:
			AudioManager.play_sfx("wheel_click")

		if t >= 1.0:
			is_spinning = false
			wheel_angle = target_angle
			if wheel_disc:
				wheel_disc.rotation = target_angle
			if pointer_sprite:
				pointer_sprite.rotation = 0.0
			_on_wheel_stopped()

# ------------------------------------------------------------------------------
# PHASE 2: 15-SECOND CHALLENGE / REWARD PHASE (4.0 to 19.0s)
# ------------------------------------------------------------------------------
func _process_challenge_phase(_delta: float) -> void:
	if current_phase != Phase.CHALLENGE_PHASE:
		current_phase = Phase.CHALLENGE_PHASE
		_activate_outcome_ui()

	var phase_remaining := maxf(0.0, 19.0 - time_elapsed)
	countdown_label.text = "⏳ Challenge Phase: %.1f seconds remaining" % phase_remaining
	
	# Gentle animation on outcome icon
	if outcome_icon:
		var pulse := 1.0 + sin(time_elapsed * 4.0) * 0.05
		outcome_icon.scale = Vector2(pulse, pulse)

# ------------------------------------------------------------------------------
# PHASE 3: CELEBRATION PHASE (19.0 to 24.0s)
# ------------------------------------------------------------------------------
func _process_celebration_phase(_delta: float) -> void:
	if current_phase != Phase.CELEBRATION_PHASE:
		current_phase = Phase.CELEBRATION_PHASE
		_trigger_celebration_effects()

	var phase_remaining := maxf(0.0, 24.0 - time_elapsed)
	countdown_label.text = "✨ Result Celebration: %.1f seconds" % phase_remaining

# ------------------------------------------------------------------------------
# PHASE 4: GRAND FINALE (24.0 to 30.0s)
# ------------------------------------------------------------------------------
func _process_finale_phase(_delta: float) -> void:
	if current_phase != Phase.FINALE_PHASE:
		current_phase = Phase.FINALE_PHASE
		AudioManager.play_sfx("legend_fanfare")
		event_title.text = "🎡 CARNIVAL VICTORY! 🏆"
		event_desc.text = "All 5 levels conquered! You are a carnival superstar!"
		hud.set_instruction("Grand Carnival Finale! Concluding 30s round... 🏆")

	var secs_left := int(TOTAL_ROUND_TIME - time_elapsed) + 1
	countdown_label.text = "🌟 Concluding session in %d seconds..." % max(1, secs_left)

# ------------------------------------------------------------------------------
# WHEEL INTERACTION & SPIN TRIGGER
# ------------------------------------------------------------------------------
func _on_spin_btn_pressed() -> void:
	if is_spinning or current_phase != Phase.INTRO_SPIN or level_finished:
		return
	_start_wheel_spin()

func _start_wheel_spin() -> void:
	if is_spinning:
		return
	is_spinning = true
	spin_time_elapsed = 0.0
	spin_duration = 3.6
	
	spin_btn.disabled = true
	
	# Choose random outcome among exactly 7 slices
	target_slice_idx = randi() % 7
	GameManager.level5_wheel_outcome = SLICES[target_slice_idx]
	
	# Mathematically calculate angle so that slice `target_slice_idx` lands under the top pointer (-PI/2)
	# Formula: (TAU * 5.0) + (7 - target_slice_idx) * (TAU / 7.0)
	target_angle = (TAU * 5.0) + ((7 - target_slice_idx) % 7) * (TAU / 7.0)
	
	AudioManager.play_sfx("wheel_click")
	hud.set_instruction("🎡 The Lucky Chaos Wheel is spinning! Where will it land?")

func _on_wheel_stopped() -> void:
	AudioManager.play_sfx("wheel_win")
	hud.set_instruction("Result: %s!" % SLICES[target_slice_idx])
	GameManager.level5_wheel_completed = true

func _activate_outcome_ui() -> void:
	event_overlay.visible = true
	if outcome_textures.has(target_slice_idx):
		outcome_icon.texture = outcome_textures[target_slice_idx]
		outcome_icon.pivot_offset = outcome_icon.size * 0.5
	
	match target_slice_idx:
		0:
			event_title.text = "LUCKY PEN 🖊️"
			event_desc.text = "You won the Whimsical Pen! Sparkling with creative inspiration!"
			active_challenge_name = "pen"
			AudioManager.play_sfx("crystal")
			hud.set_instruction("🖊️ Lucky Pen won! Enjoy your 20-second prize reveal!")
		1:
			event_title.text = "CHOCOLATE SURPRISE 🍫"
			event_desc.text = "Delicious sweet chocolate prize awarded! Savor your carnival treat!"
			active_challenge_name = "chocolate"
			AudioManager.play_sfx("combo")
			hud.set_instruction("🍫 Chocolate Surprise won! Savor your 20-second sweet reward!")
		2:
			event_title.text = "STICKER BLAST 🌈"
			event_desc.text = "Rainbow sticker blast unlocked! Sparkling carnival stickers burst across the screen!"
			active_challenge_name = "stickers"
			AudioManager.play_sfx("chime")
			hud.set_instruction("🌈 Sticker Blast unlocked! 20-second sticker celebration!")
		3:
			event_title.text = "KEYCHAIN QUEST 🔑"
			event_desc.text = "Adorable lucky carnival cat keychain won! A charming keepsake for your journey!"
			active_challenge_name = "keychain"
			AudioManager.play_sfx("crystal")
			hud.set_instruction("🔑 Keychain Quest won! 20-second souvenir reveal!")
		4:
			event_title.text = "FUNNY ACTIONS 😂"
			event_desc.text = "Do a silly pose, funny face, or tilt your head! (Full 20-Second Challenge!)"
			active_challenge_name = "funny_actions"
			AudioManager.play_sfx("boing")
			hud.set_instruction("😂 Strike silly poses and funny faces for 20 seconds!")
		5:
			event_title.text = "CHICKEN DANCE 🐔"
			event_desc.text = "Flap your arms like chicken wings, wiggle your body & dance! (Full 20 Seconds!)"
			active_challenge_name = "chicken_dance"
			AudioManager.play_sfx("quack")
			hud.set_instruction("🐔 Flap your wings & wiggle your body for 20 seconds!")
			_spawn_ducks()
		6:
			event_title.text = "ROBOT DANCE 🤖"
			event_desc.text = "Move with stiff arms, robotic steps, and funny robotic poses! (Full 20 Seconds!)"
			active_challenge_name = "robot_dance"
			AudioManager.play_sfx("boing")
			hud.set_instruction("🤖 Move with stiff arms & robotic poses for 20 seconds!")

func _trigger_celebration_effects() -> void:
	AudioManager.play_sfx("combo")
	if active_challenge_name in ["chicken_dance", "robot_dance", "funny_actions"]:
		event_title.text = "CHALLENGE CONQUERED! 🎉"
		event_desc.text = "Spectacular carnival performance! The crowd cheers wildly for your energy!"
	else:
		event_title.text = "PRIZE CLAIMED! 🌟"
		event_desc.text = "Awesome! Your prize has been officially recorded in your Memory Scrapbook!"

func _spawn_ducks() -> void:
	for i in range(12):
		var duck := Node2D.new()
		duck.position = Vector2(randf_range(80, 1200), randf_range(300, 620))
		ducks_container.add_child(duck)
		var tw := create_tween().set_loops(3)
		tw.tween_property(duck, "position:x", duck.position.x + randf_range(-140, 140), 1.2)
		tw.tween_callback(func(): AudioManager.play_sfx("quack"))

# Hand Touch Navigation with Sensible Input Debounce
func _on_hand_detected(cursor_pos: Vector2, swipe: String, waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if level_finished:
		return
		
	if current_phase == Phase.CHALLENGE_PHASE and waving and pose_feedback_timer <= 0.0:
		pose_feedback_timer = 0.8
		AudioManager.play_sfx("boing")
		hud.set_instruction("✨ Wiggle Attack recognized! Hands moving fast! Keep wiggling!")
		return

	if is_spinning or current_phase != Phase.INTRO_SPIN:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - last_touch_time < 1.0:
		return

	var screen_pos := Vector2(cursor_pos.x * 1280.0, cursor_pos.y * 720.0)
	var center := Vector2(640.0, 310.0)
	var radius := 220.0
	var dist := screen_pos.distance_to(center)

	if dist <= radius or (dist <= radius + 60.0 and swipe != "none"):
		if can_touch_spin:
			can_touch_spin = false
			last_touch_time = now
			touch_pos = screen_pos
			touch_feedback_time = 0.85
			AudioManager.play_sfx("swish")
			_start_wheel_spin()
	elif dist > radius + 70.0:
		can_touch_spin = true

func _on_face_detected(expr: String, _scores: Dictionary, _eye_sec: float) -> void:
	if current_phase != Phase.CHALLENGE_PHASE or pose_feedback_timer > 0.0:
		return
	if active_challenge_name == "funny_actions" and expr != "neutral":
		pose_feedback_timer = 0.8
		AudioManager.play_sfx("boing")
		hud.set_instruction("😂 Silly face recognized: %s! Fantastic expression!" % expr.to_upper())

func _on_pose_detected(gest: String, lean: String, _amt: float, hr: bool, ae: bool, sq: bool, cd: bool) -> void:
	if current_phase != Phase.CHALLENGE_PHASE or pose_feedback_timer > 0.0:
		return

	if active_challenge_name == "chicken_dance" and (cd or gest in ["chicken_dance", "dance"] or ae):
		pose_feedback_timer = 0.8
		AudioManager.play_sfx("quack")
		hud.set_instruction("🐔 Great chicken dance flapping! Keep wiggling!")
	elif active_challenge_name == "robot_dance" and (ae or hr or gest in ["arms_extended", "hero_pose"]):
		pose_feedback_timer = 0.8
		AudioManager.play_sfx("boing")
		hud.set_instruction("🤖 Stiff robot moves recognized! Beep boop!")
	elif active_challenge_name == "funny_actions":
		if hr:
			pose_feedback_timer = 0.8
			AudioManager.play_sfx("combo")
			hud.set_instruction("🙌 Hands Up! Pose held high!")
		elif lean != "neutral":
			pose_feedback_timer = 0.8
			AudioManager.play_sfx("quack")
			hud.set_instruction("🐧 Penguin Waddle from side to side recognized!")
		elif sq or gest != "neutral":
			pose_feedback_timer = 0.8
			AudioManager.play_sfx("boing")
			hud.set_instruction("😂 Silly carnival action recognized! Wahaha!")

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	level_finished = true
	event_overlay.visible = false
	
	hud.set_instruction("TIME'S UP! 🎡 Carnival Conquered! Off to Surprise Wonderland! 🏆")
	AudioManager.play_sfx("combo")
	
	GameManager.level5_wheel_completed = true
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		GameManager.complete_level(5)
		GameManager.load_secret_ending(true)
	)

# ------------------------------------------------------------------------------
# ILLUSTRATED CARNIVAL BUNTING & STAGE DRAWING
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

	# B. Carnival Stage Platform at Bottom
	carnival_canvas.draw_rect(Rect2(0, 580, 1280, 140), Color(0.38, 0.20, 0.15))
	carnival_canvas.draw_line(Vector2(0, 580), Vector2(1280, 580), Color(1.0, 0.82, 0.25), 6.0)
	for b in range(20):
		var bx := 32.0 + b * 64.0
		var bulb_col := Color(1.0, 0.9, 0.3) if (b + int(time_elapsed * 4.0)) % 2 == 0 else Color(0.2, 0.95, 1.0)
		carnival_canvas.draw_circle(Vector2(bx, 580), 7.0, bulb_col)

	# C. Touch-to-Spin Visual Feedback Ripple
	if touch_feedback_time > 0.0:
		var ripple_t := 1.0 - (touch_feedback_time / 0.85)
		var ripple_r := ripple_t * 65.0 + 20.0
		var alpha := clampf(touch_feedback_time / 0.85, 0.0, 1.0)
		carnival_canvas.draw_circle(touch_pos, ripple_r, Color(1.0, 0.9, 0.3, alpha * 0.35))
		carnival_canvas.draw_arc(touch_pos, ripple_r, 0.0, TAU, 32, Color(0.2, 0.95, 1.0, alpha), 4.0)
