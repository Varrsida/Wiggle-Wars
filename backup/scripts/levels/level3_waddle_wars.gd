extends Node2D

## WIGGLE WARS! — Level 3: Waddle Wars 🐧
## The Cute Penguin Adventure
## Controls the adorable baby penguin with player body pose:
## Leans, jumps, belly slide, balance flippers, squats, and reaching!
## Features random penguin events: Banana Wobble, Snowball Chase, Penguin Parade, Dizzy Penguin.

@onready var hud: CanvasLayer = $HUD
@onready var penguin_node: Node2D = $Penguin
@onready var crystals_container: Node2D = $CrystalsContainer
@onready var snow_particles: CPUParticles2D = $SnowParticles
@onready var obstacle_container: Node2D = $ObstacleContainer

var penguin_x: float = 640.0
var penguin_y: float = 560.0
var base_y: float = 560.0
var penguin_state: String = "idle" # idle, jump, slide, balance, squat, reach, wobble, dizzy
var state_timer: float = 0.0

var crystals_collected: int = 0
var time_elapsed: float = 0.0
var next_event_time: float = 6.0
var level_finished: bool = false

# Cooldowns
var last_pose_time: float = 0.0
const POSE_COOLDOWN: float = 0.65

# Floating crystals
class Crystal:
	var node: Node2D
	var pos: Vector2
	var collected: bool = false
	var is_high: bool = false # requires reach or jump

var active_crystals: Array[Crystal] = []

func _ready() -> void:
	hud.setup_hud("Level 3: Waddle Wars 🐧", "Move your body: Lean left/right, jump, and slide!")
	GestureListener.pose_detected.connect(_on_pose_detected)
	GestureListener.hand_detected.connect(_on_hand_detected)
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level3.wav",
		"Meet our adorable baby penguin! Lean, jump, and slide to help our cute little hero!", 6.0)

	_spawn_crystals_wave()

func _spawn_crystals_wave() -> void:
	for i in range(8):
		var c := Crystal.new()
		var n := Node2D.new()
		var is_high := (i % 2 == 1)
		var cx := 200.0 + i * 125.0
		var cy := 420.0 if is_high else 550.0
		c.pos = Vector2(cx, cy)
		c.is_high = is_high
		n.position = c.pos
		crystals_container.add_child(n)
		c.node = n
		active_crystals.append(c)

func _process(delta: float) -> void:
	time_elapsed += delta
	_update_state(delta)
	_update_penguin_motion(delta)
	_check_random_events(delta)
	queue_redraw()

func _update_state(delta: float) -> void:
	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0:
			penguin_state = "idle"

func _update_penguin_motion(delta: float) -> void:
	# Check crystal collisions based on penguin state & position
	for c in active_crystals:
		if c.collected:
			continue
		var dist := Vector2(penguin_x, penguin_y).distance_to(c.pos)
		
		# Belly slide collects low crystals rapidly
		if penguin_state == "slide" and not c.is_high and abs(penguin_x - c.pos.x) < 70.0:
			_collect_crystal(c, 5)
		# Reaching upward or jumping collects high crystals
		elif (penguin_state == "reach" or penguin_state == "jump") and c.is_high and abs(penguin_x - c.pos.x) < 70.0:
			_collect_crystal(c, 15)
		# Normal proximity
		elif dist < 50.0 and not c.is_high:
			_collect_crystal(c, 10)

func _collect_crystal(c: Crystal, points: int) -> void:
	c.collected = true
	crystals_collected += 1
	GameManager.add_score(points)
	AudioManager.play_sfx("crystal")
	hud.set_instruction("💎 Crystal Collected! (+%d)" % points)
	
	var tw := create_tween()
	tw.tween_property(c.node, "scale", Vector2(1.8, 1.8), 0.2)
	tw.parallel().tween_property(c.node, "modulate:a", 0.0, 0.3)
	tw.tween_callback(c.node.queue_free)
	
	if crystals_collected >= 6 and not level_finished:
		level_finished = true
		hud.set_instruction("🐧 PENGUIN HERO VICTORY! All crystals gathered!")
		AudioManager.play_sfx("legend_fanfare")
		
		var fin_tw := create_tween()
		fin_tw.tween_interval(2.2)
		fin_tw.tween_callback(func():
			GameManager.complete_level(3)
			get_tree().change_scene_to_file("res://scenes/level_results.tscn")
		)

func _on_pose_detected(gest: String, lean: String, _lean_amt: float, hr: bool, ae: bool, sq: bool, _cd: bool) -> void:
	if level_finished or penguin_state in ["wobble", "dizzy"]:
		return

	var now := Time.get_ticks_msec() / 1000.0

	# 1. Lean left
	if lean == "lean_left" or gest == "lean_left":
		penguin_x = clampf(penguin_x - 14.0, 160.0, 1120.0)
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			GameManager.add_score(10)
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Leaning Left! Dodge move! (+10)")

	# 2. Lean right
	elif lean == "lean_right" or gest == "lean_right":
		penguin_x = clampf(penguin_x + 14.0, 160.0, 1120.0)
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			GameManager.add_score(10)
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Leaning Right! Dodge move! (+10)")

	# 3. Raise both hands -> Jump
	elif hr or gest == "hands_raised":
		if penguin_state != "jump":
			penguin_state = "jump"
			state_timer = 0.6
			AudioManager.play_sfx("jump")
			GameManager.add_score(10)
			hud.set_instruction("🐧 Hands Raised! Penguin Jumps High! (+10)")

	# 4. Arms Extended Sideways -> Balance
	elif ae or gest == "arms_extended":
		penguin_state = "balance"
		state_timer = 0.5
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			GameManager.add_score(15)
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Arms Extended! Flippers Balanced! (+15)")

	# 5. Squat -> Tiny Penguin Pose
	elif sq or gest == "squat":
		penguin_state = "squat"
		state_timer = 0.5
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			GameManager.add_score(10)
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Squatting! Adorable Tiny Penguin Pose! (+10)")

	# 6. Lean Forward -> Belly Slide
	elif gest == "lean_forward":
		penguin_state = "slide"
		state_timer = 0.8
		penguin_x = clampf(penguin_x + 8.0, 160.0, 1120.0)
		AudioManager.play_sfx("slide")
		hud.set_instruction("🐧 Belly Slide! Sliding across ice! Collect crystals!")

func _on_hand_detected(_pos: Vector2, _swipe: String, _waving: bool, _wave_spd: float, reach_up: bool, _open: bool, _fist: bool) -> void:
	if reach_up and penguin_state != "reach":
		penguin_state = "reach"
		state_timer = 0.6
		AudioManager.play_sfx("chirp")
		hud.set_instruction("🐧 Reaching Upward! Grabbing high crystals!")

func _check_random_events(_delta: float) -> void:
	if time_elapsed > next_event_time and not level_finished:
		next_event_time = time_elapsed + randf_range(8.0, 12.0)
		var ev_roll := randi() % 4
		match ev_roll:
			0:
				_trigger_banana_wobble()
			1:
				_trigger_snowball_chase()
			2:
				_trigger_penguin_parade()
			3:
				_trigger_dizzy_penguin()

func _trigger_banana_wobble() -> void:
	penguin_state = "wobble"
	state_timer = 1.6
	AudioManager.play_sfx("chirp")
	hud.set_instruction("🍌 Banana-Foot Wobble! Flippers waving frantically!")

func _trigger_snowball_chase() -> void:
	hud.set_instruction("❄️ Snowball Chase! A big snowball is rolling! Lean to dodge!")
	var snowball := Node2D.new()
	snowball.position = Vector2(0.0, base_y - 15.0)
	obstacle_container.add_child(snowball)
	
	var tw := create_tween()
	tw.tween_property(snowball, "position:x", 1350.0, 2.2)
	tw.tween_callback(snowball.queue_free)

func _trigger_penguin_parade() -> void:
	hud.set_instruction("🐧 PENGUIN PARADE! Cheerful tiny baby penguins waddling by!")
	AudioManager.play_sfx("chirp")
	for i in range(5):
		var parade_p := Node2D.new()
		parade_p.position = Vector2(-80.0 - i * 60.0, base_y + 10.0)
		obstacle_container.add_child(parade_p)
		
		var tw := create_tween()
		tw.tween_property(parade_p, "position:x", 1380.0 + i * 60.0, 3.5)
		tw.tween_callback(parade_p.queue_free)

func _trigger_dizzy_penguin() -> void:
	penguin_state = "dizzy"
	state_timer = 1.8
	AudioManager.play_sfx("chirp")
	hud.set_instruction("💫 Dizzy Penguin! Stars circling cute little head!")

func _draw() -> void:
	# Draw Crystals
	for c in active_crystals:
		if not c.collected:
			var cp := c.pos
			draw_polygon(PackedVector2Array([
				cp + Vector2(0, -20), cp + Vector2(14, -5),
				cp + Vector2(0, 20), cp + Vector2(-14, -5)
			]), PackedColorArray([Color(0.3, 0.8, 1.0, 0.9)]))
			draw_circle(cp, 4.0, Color.WHITE)

	# Calculate penguin vertical offset based on state
	var p_draw_y := base_y
	var squash := Vector2(1.0, 1.0)
	var waddle := sin(time_elapsed * 6.0) * 0.12
	
	match penguin_state:
		"jump":
			p_draw_y -= 110.0
			squash = Vector2(0.85, 1.25)
		"slide":
			p_draw_y += 15.0
			squash = Vector2(1.4, 0.6)
		"squat":
			p_draw_y += 20.0
			squash = Vector2(1.2, 0.7)
		"wobble":
			waddle = sin(time_elapsed * 18.0) * 0.4
		"dizzy":
			# Draw circling stars
			for s in range(3):
				var a := time_elapsed * 5.0 + s * (TAU / 3.0)
				var star_pos := Vector2(penguin_x + cos(a) * 35.0, p_draw_y - 85.0 + sin(a) * 10.0)
				draw_circle(star_pos, 5.0, Color(1.0, 0.9, 0.2))

	var p_pos := Vector2(penguin_x, p_draw_y)
	
	# Draw Penguin Hero
	# 1. Orange feet
	draw_ellipse(p_pos + Vector2(-16, 22), 12.0 * squash.x, 6.0 * squash.y, Color(1.0, 0.55, 0.1))
	draw_ellipse(p_pos + Vector2(16, 22), 12.0 * squash.x, 6.0 * squash.y, Color(1.0, 0.55, 0.1))
	
	# 2. Black Body
	draw_ellipse(p_pos, 38.0 * squash.x, 48.0 * squash.y, Color(0.12, 0.14, 0.2))
	
	# 3. White Belly
	draw_ellipse(p_pos + Vector2(0, 4), 26.0 * squash.x, 38.0 * squash.y, Color.WHITE)
	
	# 4. Tiny Flippers (Rotate with waddle/balance)
	var flipper_angle := 0.2 if penguin_state != "balance" else 1.4
	draw_ellipse(p_pos + Vector2(-36, 0), 10.0, 22.0, Color(0.12, 0.14, 0.2))
	draw_ellipse(p_pos + Vector2(36, 0), 10.0, 22.0, Color(0.12, 0.14, 0.2))
	
	# 5. Head
	var head_pos := p_pos + Vector2(0, -42.0 * squash.y)
	draw_circle(head_pos, 28.0, Color(0.12, 0.14, 0.2))
	
	# 6. Big Expressive Eyes
	draw_circle(head_pos + Vector2(-10, -6), 9.0, Color.WHITE)
	draw_circle(head_pos + Vector2(10, -6), 9.0, Color.WHITE)
	draw_circle(head_pos + Vector2(-9, -6), 5.0, Color(0.1, 0.1, 0.2))
	draw_circle(head_pos + Vector2(11, -6), 5.0, Color(0.1, 0.1, 0.2))
	# Eye sparkle highlights
	draw_circle(head_pos + Vector2(-11, -8), 2.5, Color.WHITE)
	draw_circle(head_pos + Vector2(9, -8), 2.5, Color.WHITE)
	
	# 7. Cute Orange Beak
	draw_polygon(PackedVector2Array([
		head_pos + Vector2(0, 8),
		head_pos + Vector2(-7, 0),
		head_pos + Vector2(7, 0)
	]), PackedColorArray([Color(1.0, 0.6, 0.1)]))
