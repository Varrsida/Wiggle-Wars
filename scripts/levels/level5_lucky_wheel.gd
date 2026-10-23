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
@onready var challenge_label: Label = get_node_or_null("EventOverlay/Panel/Margin/VBox/ChallengeLabel")
@onready var outcome_icon: TextureRect = $EventOverlay/Panel/Margin/VBox/OutcomeIcon
@onready var score_label: Label = get_node_or_null("EventOverlay/Panel/Margin/VBox/ScoreLabel")
@onready var event_desc: Label = $EventOverlay/Panel/Margin/VBox/EventDesc
@onready var countdown_label: Label = $EventOverlay/Panel/Margin/VBox/CountdownLabel
@onready var continue_btn: Button = get_node_or_null("EventOverlay/Panel/Margin/VBox/ContinueBtn")

const SLICES: Array[String] = [
	"Silly Dance 🤖",
	"Funny Face 😂",
	"Hands Up! 🙌",
	"Penguin Waddle 🐧",
	"Wiggle Attack 👋"
]

var outcome_textures: Dictionary = {
	0: preload("res://assets/sprites/challenge_silly_dance.png"),
	1: preload("res://assets/sprites/challenge_funny_face.png"),
	2: preload("res://assets/sprites/challenge_hands_up.png"),
	3: preload("res://assets/sprites/challenge_penguin_waddle.png"),
	4: preload("res://assets/sprites/challenge_wiggle_attack.png")
}

# Round Phases (Strict 20-Second Master Timeline)
enum Phase {
	INTRO_SHOW,        # 0.0 - 3.0s (Show wheel and introduce challenge)
	WHEEL_SPIN,        # 3.0 - 6.0s (Spin wheel visibly & settle on selected sector)
	CHALLENGE_PHASE,   # 6.0 - 18.0s (Perform selected challenge with live webcam tracker)
	RESULT_PHASE       # 18.0 - 20.0s (Show result & transition to Surprise Wonderland)
}

var current_phase: Phase = Phase.INTRO_SHOW
var time_elapsed: float = 0.0
const TOTAL_ROUND_TIME: float = 20.0
var level_finished: bool = false
var challenge_success: bool = false
var result_displayed: bool = false

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
var challenge_progress: float = 0.0
var challenge_target: float = 3.0
var challenge_action_count: int = 0
var last_lean_direction: String = "neutral"
var is_active_pose_matching: bool = false
var is_active_face_matching: bool = false
var is_active_hand_matching: bool = false
var last_matching_input_time: float = 0.0

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
		"Step right up to the Lucky Chaos Wheel! Spin for wild prizes and hilarious surprises for the next 20 seconds!", 5.0)

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

	# Master State Machine (Strict 20-Second Timeline)
	# 0.0 - 3.0s: Intro Show (player can spin, or auto-spins at 3.0s)
	# 3.0 - 6.0s: Wheel Spin (3-second visible spin settling on target sector)
	# 6.0 - 18.0s: Challenge Phase (12-second live webcam activity)
	# 18.0 - 20.0s: Result Phase & Transition to Surprise Wonderland
	if time_elapsed < 3.0:
		_process_intro_show_phase(delta)
	elif time_elapsed < 6.0:
		_process_wheel_spin_phase(delta)
	elif time_elapsed < 18.0:
		if not result_displayed:
			_process_challenge_phase(delta)
		else:
			_process_result_phase(delta)
	elif time_elapsed < TOTAL_ROUND_TIME:
		_process_result_phase(delta)
	else:
		_on_level_timer_complete()

	if touch_feedback_time > 0.0:
		touch_feedback_time -= delta

	if pose_feedback_timer > 0.0:
		pose_feedback_timer -= delta

	if carnival_canvas:
		carnival_canvas.queue_redraw()

# ------------------------------------------------------------------------------
# PHASE 1: INTRO SHOW (0.0 to 3.0s)
# ------------------------------------------------------------------------------
func _process_intro_show_phase(_delta: float) -> void:
	current_phase = Phase.INTRO_SHOW
	if time_elapsed >= 3.0 and not is_spinning:
		_start_wheel_spin()

# ------------------------------------------------------------------------------
# PHASE 2: WHEEL SPIN (3.0 to 6.0s)
# ------------------------------------------------------------------------------
func _process_wheel_spin_phase(delta: float) -> void:
	current_phase = Phase.WHEEL_SPIN
	if not is_spinning:
		_start_wheel_spin()

	spin_time_elapsed += delta
	var t := clampf(spin_time_elapsed / spin_duration, 0.0, 1.0)
	var ease_t := 1.0 - pow(1.0 - t, 3.0)
	wheel_angle = lerpf(0.0, target_angle, ease_t)
	if wheel_disc:
		wheel_disc.rotation = wheel_angle

	if pointer_sprite:
		pointer_sprite.rotation = sin(spin_time_elapsed * 28.0 * (1.0 - t)) * 0.12

	# Click audio ticks
	if fmod(wheel_angle, TAU / 5.0) < 0.25:
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
# PHASE 3: 12-SECOND CHALLENGE PHASE (6.0 to 18.0s)
# ------------------------------------------------------------------------------
func _process_challenge_phase(delta: float) -> void:
	if current_phase != Phase.CHALLENGE_PHASE:
		current_phase = Phase.CHALLENGE_PHASE
		_activate_outcome_ui()

	var phase_remaining := maxf(0.0, 18.0 - time_elapsed)
	
	# Input decay check
	if time_elapsed - last_matching_input_time > 0.45:
		is_active_pose_matching = false
		is_active_face_matching = false
		is_active_hand_matching = false

	# Accumulate progress for continuous poses and gestures
	match active_challenge_name:
		"robot_dance":
			if is_active_pose_matching:
				challenge_progress += delta
			countdown_label.text = "⏳ Time: %.1fs | 🤖 Robot Moves: %.1f / 3.0s" % [phase_remaining, minf(3.0, challenge_progress)]
			if challenge_progress >= 3.0:
				hud.set_instruction("✨ Silly Robot Dance completed! Fantastic robotic rhythm!")
				_show_final_result(true)
		"funny_actions":
			if is_active_face_matching:
				challenge_progress += delta
			countdown_label.text = "⏳ Time: %.1fs | 😂 Silly Face: %.1f / 3.0s" % [phase_remaining, minf(3.0, challenge_progress)]
			if challenge_progress >= 3.0:
				hud.set_instruction("✨ Silly Face completed! What a delightfully silly face!")
				_show_final_result(true)
		"hands_up":
			if is_active_pose_matching:
				challenge_progress += delta
			countdown_label.text = "⏳ Time: %.1fs | 🙌 Hands Up: %.1f / 3.0s" % [phase_remaining, minf(3.0, challenge_progress)]
			if challenge_progress >= 3.0:
				hud.set_instruction("✨ Hands Up completed! Reaching for the carnival sky!")
				_show_final_result(true)
		"chicken_dance":
			if is_active_pose_matching:
				challenge_progress += delta
			countdown_label.text = "⏳ Time: %.1fs | 🐧 Waddles: %d / 4 (%.1fs)" % [phase_remaining, challenge_action_count, minf(3.0, challenge_progress)]
			if challenge_action_count >= 4 or challenge_progress >= 3.0:
				hud.set_instruction("✨ Penguin Waddle completed! Cutest arctic moves!")
				_show_final_result(true)
		"wiggle_attack":
			if is_active_hand_matching:
				challenge_progress += delta
				if int(challenge_progress * 1.5) > challenge_action_count:
					challenge_action_count = int(challenge_progress * 1.5)
			countdown_label.text = "⏳ Time: %.1fs | 👋 Wiggles: %d / 4 (%.1fs)" % [phase_remaining, challenge_action_count, minf(3.0, challenge_progress)]
			if challenge_action_count >= 4 or challenge_progress >= 3.0:
				hud.set_instruction("✨ Wiggle Attack completed! Pure chaotic carnival energy!")
				_show_final_result(true)

	if outcome_icon:
		var pulse := 1.0 + sin(time_elapsed * 4.0) * 0.05
		outcome_icon.scale = Vector2(pulse, pulse)

# ------------------------------------------------------------------------------
# PHASE 3: RESULT PHASE (18.0 to 20.0s or immediate on early completion)
# ------------------------------------------------------------------------------
func _show_final_result(success: bool) -> void:
	if result_displayed:
		return
	result_displayed = true
	challenge_success = success
	current_phase = Phase.RESULT_PHASE
	event_overlay.visible = true
	
	if success:
		event_title.text = "SUCCESSFULLY COMPLETED! 🎉"
		if challenge_label:
			challenge_label.visible = true
			challenge_label.text = "Challenge Completed: %s" % SLICES[target_slice_idx]
		
		if score_label:
			score_label.visible = true
			match target_slice_idx:
				0:
					score_label.text = "Robot Moves: 3.0s Dance Held ✔"
				1:
					score_label.text = "Silly Face: 3.0s Expression Registered ✔"
				2:
					score_label.text = "Pose Held: Both Hands High Raised ✔"
				3:
					score_label.text = "Waddle Count: Side-to-Side Flaps Completed ✔"
				4:
					score_label.text = "Wiggle Speed: Fast Wave Swipes Detected ✔"
		
		match target_slice_idx:
			0:
				event_desc.text = "Beep boop! Fantastic robotic rhythm and carnival energy!"
			1:
				event_desc.text = "Wahaha! What a delightfully silly face! The crowd loves it!"
			2:
				event_desc.text = "Woohoo! Reaching for the carnival sky with amazing cheer!"
			3:
				event_desc.text = "Quack & waddle! The cutest arctic moves at the carnival!"
			4:
				event_desc.text = "Incredible wiggle speed! Pure chaotic carnival champion energy!"
		
		if countdown_label:
			countdown_label.visible = false
		if continue_btn:
			continue_btn.visible = true
			continue_btn.text = "CONTINUE ➔"
		
		AudioManager.play_sfx("combo")
		hud.set_instruction("✨ Challenge Completed: %s! ✨" % SLICES[target_slice_idx])
	else:
		event_title.text = "YOU TRIED YOUR BEST! KEEP WIGGLING! 💗"
		if challenge_label:
			challenge_label.visible = true
			challenge_label.text = "Challenge: %s" % SLICES[target_slice_idx]
		if score_label:
			score_label.visible = false
		event_desc.text = "Great effort! Wonderful energy! Off to Surprise Wonderland!"
		if countdown_label:
			countdown_label.visible = true
		if continue_btn:
			continue_btn.visible = true
			continue_btn.text = "CONTINUE ➔"
		AudioManager.play_sfx("chime")
		hud.set_instruction("YOU TRIED YOUR BEST! KEEP WIGGLING! 💗")

func _process_result_phase(_delta: float) -> void:
	if not result_displayed:
		_show_final_result(challenge_success)
		
	var time_left := maxf(0.0, TOTAL_ROUND_TIME - time_elapsed)
	if countdown_label and countdown_label.visible:
		countdown_label.text = "🌟 Off to Surprise Wonderland in %.1f seconds..." % time_left

# ------------------------------------------------------------------------------
# WHEEL INTERACTION & SPIN TRIGGER
# ------------------------------------------------------------------------------
func _on_spin_btn_pressed() -> void:
	if is_spinning or current_phase != Phase.INTRO_SHOW or level_finished:
		return
	_start_wheel_spin()

func set_target_sector(idx: int) -> void:
	target_slice_idx = posmod(idx, 5)
	GameManager.level5_wheel_outcome = SLICES[target_slice_idx]
	var sector_phi: float = float(target_slice_idx) * (2.0 * PI / 5.0)
	var landing_offset := fmod(TAU - sector_phi, TAU)
	target_angle = (TAU * 5.0) + landing_offset

func _start_wheel_spin(forced_sector: int = -1) -> void:
	if is_spinning:
		return
	is_spinning = true
	spin_time_elapsed = 0.0
	spin_duration = 3.0
	
	if spin_btn:
		spin_btn.disabled = true
	
	if forced_sector >= 0:
		set_target_sector(forced_sector)
	else:
		set_target_sector(randi() % 5)
	
	AudioManager.play_sfx("wheel_click")
	hud.set_instruction("🎡 The Lucky Chaos Wheel is spinning! Where will it land?")

func _on_wheel_stopped() -> void:
	AudioManager.play_sfx("wheel_win")
	hud.set_instruction("Result: %s!" % SLICES[target_slice_idx])
	GameManager.level5_wheel_completed = true

func _activate_outcome_ui() -> void:
	event_overlay.visible = true
	challenge_progress = 0.0
	challenge_target = 3.0
	challenge_action_count = 0
	last_lean_direction = "neutral"
	is_active_pose_matching = false
	is_active_face_matching = false
	is_active_hand_matching = false
	last_matching_input_time = 0.0

	if outcome_textures.has(target_slice_idx):
		outcome_icon.texture = outcome_textures[target_slice_idx]
		outcome_icon.pivot_offset = outcome_icon.size * 0.5
	
	if continue_btn:
		continue_btn.visible = false
	if score_label:
		score_label.visible = false
	if challenge_label:
		challenge_label.visible = true
		challenge_label.text = "🎡 Challenge in Progress..."
	if countdown_label:
		countdown_label.visible = true
	
	match target_slice_idx:
		0:
			event_title.text = "SILLY DANCE 🤖"
			event_desc.text = "Move and dance with fun robotic moves for 5 seconds!"
			active_challenge_name = "robot_dance"
			AudioManager.play_sfx("boing")
			hud.set_instruction("🤖 Move and dance with stiff robotic moves!")
		1:
			event_title.text = "FUNNY FACE 😂"
			event_desc.text = "Make a silly face and hold it for 3 seconds!"
			active_challenge_name = "funny_actions"
			AudioManager.play_sfx("boing")
			hud.set_instruction("😂 Make a silly face and hold it for 3 seconds!")
		2:
			event_title.text = "HANDS UP! 🙌"
			event_desc.text = "Raise both hands high to celebrate the carnival!"
			active_challenge_name = "hands_up"
			AudioManager.play_sfx("combo")
			hud.set_instruction("🙌 Raise both hands high in the air!")
		3:
			event_title.text = "PENGUIN WADDLE 🐧"
			event_desc.text = "Move like a penguin from side to side or flap your wings!"
			active_challenge_name = "chicken_dance"
			AudioManager.play_sfx("quack")
			hud.set_instruction("🐧 Move like a penguin from side to side!")
			_spawn_ducks()
		4:
			event_title.text = "WIGGLE ATTACK 👋"
			event_desc.text = "Wiggle both hands quickly to unleash the wiggle attack!"
			active_challenge_name = "wiggle_attack"
			AudioManager.play_sfx("crystal")
			hud.set_instruction("👋 Wiggle both hands quickly!")

func _on_continue_pressed() -> void:
	if level_finished:
		return
	level_finished = true
	GameManager.level5_wheel_completed = true
	GameManager.complete_level(5)
	GameManager.load_secret_ending(true)

func _trigger_celebration_effects() -> void:
	AudioManager.play_sfx("combo")
	event_title.text = "CHALLENGE CONQUERED! 🎉"
	event_desc.text = "Spectacular carnival performance! The crowd cheers wildly for your energy!"

func _spawn_ducks() -> void:
	for i in range(12):
		var duck := Node2D.new()
		duck.position = Vector2(randf_range(80, 1200), randf_range(300, 620))
		ducks_container.add_child(duck)
		var tw := create_tween().set_loops(3)
		tw.tween_property(duck, "position:x", duck.position.x + randf_range(-140, 140), 1.2)
		tw.tween_callback(func(): AudioManager.play_sfx("quack"))

# Hand Touch Navigation with Sensible Input Debounce
func _on_hand_detected(cursor_pos: Vector2, swipe: String, waving: bool, _wave_spd: float, reach_up: bool, _open: bool, _fist: bool) -> void:
	if level_finished:
		return
		
	if current_phase == Phase.CHALLENGE_PHASE:
		if active_challenge_name == "wiggle_attack":
			if waving or swipe != "none":
				last_matching_input_time = time_elapsed
				is_active_hand_matching = true
				if swipe != "none":
					challenge_action_count += 1
					AudioManager.play_sfx("boing")
		elif active_challenge_name == "hands_up" and reach_up:
			last_matching_input_time = time_elapsed
			is_active_pose_matching = true

	if is_spinning or current_phase != Phase.INTRO_SHOW:
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
	if current_phase != Phase.CHALLENGE_PHASE:
		return
	if active_challenge_name == "funny_actions" and expr != "neutral":
		last_matching_input_time = time_elapsed
		is_active_face_matching = true

func _on_pose_detected(gest: String, lean: String, _amt: float, hr: bool, ae: bool, sq: bool, cd: bool) -> void:
	if current_phase != Phase.CHALLENGE_PHASE:
		return

	if active_challenge_name == "hands_up" and hr:
		last_matching_input_time = time_elapsed
		is_active_pose_matching = true
	elif active_challenge_name == "chicken_dance":
		if lean != "neutral" and lean != last_lean_direction:
			last_lean_direction = lean
			challenge_action_count += 1
			AudioManager.play_sfx("quack")
		if cd or gest in ["chicken_dance", "dance"] or ae or sq or lean != "neutral":
			last_matching_input_time = time_elapsed
			is_active_pose_matching = true
	elif active_challenge_name == "robot_dance":
		if ae or hr or gest in ["arms_extended", "hero_pose", "robot_dance", "dance"]:
			last_matching_input_time = time_elapsed
			is_active_pose_matching = true
	elif active_challenge_name == "funny_actions":
		if hr or lean != "neutral" or sq or gest != "neutral":
			last_matching_input_time = time_elapsed
			is_active_face_matching = true

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	
	if not result_displayed:
		_show_final_result(challenge_success)
	
	hud.set_instruction("TIME'S UP! 🎡 Off to Surprise Wonderland! 🏆")
	AudioManager.play_sfx("combo")
	
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		if not level_finished:
			_on_continue_pressed()
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
