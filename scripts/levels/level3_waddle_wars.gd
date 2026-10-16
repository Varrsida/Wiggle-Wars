extends Node2D

## WIGGLE WARS! — Level 3: Waddle Wars 🐧
## Fully Illustrated Snowy Arctic Penguin World
## Controls the adorable baby penguin with real player body pose:
## Leans, jumps, belly slide, balance flippers, squats, and reaching!
## Exactly 60-second timer. Score system completely removed per design requirement.

@onready var hud: CanvasLayer = $HUD
@onready var arctic_canvas: Node2D = $WorldLayer/ArcticCanvas
@onready var penguin_sprite: Sprite2D = $WorldLayer/PenguinSprite
@onready var crystals_container: Node2D = $WorldLayer/CrystalsContainer
@onready var obstacle_container: Node2D = $WorldLayer/ObstacleContainer
@onready var snow_particles: CPUParticles2D = $WorldLayer/SnowParticles

var penguin_x: float = 640.0
var penguin_y: float = 560.0
var base_y: float = 560.0
var penguin_state: String = "idle" # idle, jump, slide, balance, squat, reach, wobble, dizzy
var state_timer: float = 0.0

var crystals_collected: int = 0
var fish_collected: int = 0
var time_elapsed: float = 0.0
var next_event_time: float = 7.0

# 45-Second Level Timer
var time_remaining: float = 45.0
var level_finished: bool = false

var last_pose_time: float = 0.0
const POSE_COOLDOWN: float = 0.45

# Floating crystals & ice fish
class ArcticItem:
	var id: int
	var pos: Vector2
	var is_high: bool = false
	var collected: bool = false
	var item_type: String # crystal, fish

var active_items: Array[ArcticItem] = []
var next_item_id: int = 1
var item_spawn_timer: float = 0.0

# Scenery mountain peaks & pine trees
var mountains: Array[PackedVector2Array] = []
var pine_trees: Array[Dictionary] = []
var snow_puffs: Array[Dictionary] = []
var prev_penguin_x: float = 640.0
var waddle_sound_timer: float = 0.0

func _ready() -> void:
	crystals_collected = 0
	fish_collected = 0
	GameManager.level3_crystals_collected = 0
	GameManager.level3_fish_collected = 0
	
	hud.setup_hud("Level 3: Waddle Wars 🐧", "Move your body: Lean left/right, jump, squat & slide to guide the baby penguin!")
	hud.set_timer(time_remaining)
	
	GestureListener.pose_detected.connect(_on_pose_detected)
	GestureListener.hand_detected.connect(_on_hand_detected)
	
	if arctic_canvas:
		arctic_canvas.draw.connect(_draw_arctic_canvas)
		
	_init_arctic_scenery()
	_spawn_initial_items()
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level3.wav",
		"Meet our adorable baby penguin! Lean, jump, and slide to help our cute little hero for the next 45 seconds!", 6.0)

func _init_arctic_scenery() -> void:
	# Jagged icy mountain silhouettes
	mountains.clear()
	mountains.append(PackedVector2Array([
		Vector2(-50, 560), Vector2(180, 280), Vector2(360, 420), Vector2(540, 560)
	]))
	mountains.append(PackedVector2Array([
		Vector2(420, 560), Vector2(680, 240), Vector2(880, 380), Vector2(1040, 560)
	]))
	mountains.append(PackedVector2Array([
		Vector2(920, 560), Vector2(1120, 310), Vector2(1330, 560)
	]))
	
	# Frosted Arctic Pine Trees
	pine_trees.clear()
	pine_trees.append({"pos": Vector2(120, 520), "scale": 1.2})
	pine_trees.append({"pos": Vector2(280, 535), "scale": 0.9})
	pine_trees.append({"pos": Vector2(1020, 530), "scale": 1.1})
	pine_trees.append({"pos": Vector2(1180, 515), "scale": 1.3})

func _spawn_initial_items() -> void:
	for i in range(8):
		_spawn_item(200.0 + i * 125.0)

func _spawn_item(x_pos: float) -> void:
	var item := ArcticItem.new()
	item.id = next_item_id
	next_item_id += 1
	item.is_high = (randf() < 0.45)
	item.item_type = "fish" if randf() < 0.35 else "crystal"
	var y_pos := 390.0 if item.is_high else 545.0
	item.pos = Vector2(x_pos, y_pos)
	active_items.append(item)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 60-Second Level Timer
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		if time_remaining <= 0.0:
			_on_level_timer_complete()
			
	# Continual item replenishment across 60s
	item_spawn_timer += delta
	if item_spawn_timer >= 2.5 and active_items.size() < 10:
		item_spawn_timer = 0.0
		_spawn_item(randf_range(180.0, 1100.0))
		
	_update_state(delta)
	_update_penguin_motion(delta)
	_check_random_events(delta)
	
	if arctic_canvas:
		arctic_canvas.queue_redraw()

func _update_state(delta: float) -> void:
	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0:
			penguin_state = "idle"

func _update_penguin_motion(delta: float) -> void:
	# Calculate penguin body position
	var p_pos := Vector2(penguin_x, penguin_y)
	if penguin_state == "jump":
		p_pos.y -= 110.0
		
	for it in active_items:
		if it.collected:
			continue
		var dist := p_pos.distance_to(it.pos)
		
		# Belly slide sweeps low items
		if penguin_state == "slide" and not it.is_high and abs(penguin_x - it.pos.x) < 80.0:
			_collect_item(it)
		# Jump or reach catches high items
		elif (penguin_state in ["reach", "jump"]) and it.is_high and abs(penguin_x - it.pos.x) < 80.0:
			_collect_item(it)
		# Proximity collection
		elif dist < 55.0 and not it.is_high:
			_collect_item(it)

	# Spawn snow puffs when moving horizontally or sliding
	var movement := absf(penguin_x - prev_penguin_x)
	prev_penguin_x = penguin_x
	
	if waddle_sound_timer > 0.0:
		waddle_sound_timer -= delta
	elif movement > 2.0:
		waddle_sound_timer = 0.38
		AudioManager.play_sfx("slide")
		
	if movement > 1.5 or penguin_state == "slide":
		if randf() < 0.65:
			snow_puffs.append({
				"pos": Vector2(penguin_x + randf_range(-25, 25), base_y + 105.0 + randf_range(-4, 4)),
				"vel": Vector2(randf_range(-35, 35), randf_range(-25, -6)),
				"radius": randf_range(6.0, 13.0),
				"alpha": 0.85,
				"life": 0.55
			})

	# Update active snow puffs
	var surviving_puffs: Array[Dictionary] = []
	for sp in snow_puffs:
		sp["pos"] += sp["vel"] * delta
		sp["life"] -= delta
		sp["alpha"] = clampf(sp["life"] / 0.55, 0.0, 1.0) * 0.85
		if sp["life"] > 0.0:
			surviving_puffs.append(sp)
	snow_puffs = surviving_puffs

	# Animate the authentic cute penguin sprite
	if penguin_sprite:
		var p_draw_y := base_y
		var squash := Vector2(1.0, 1.0)
		var waddle := sin(time_elapsed * 6.5) * 0.12
		var p_rot := 0.0

		match penguin_state:
			"jump":
				p_draw_y -= 110.0
				squash = Vector2(0.85, 1.25)
			"slide":
				p_draw_y += 24.0
				squash = Vector2(1.35, 0.65)
				p_rot = 0.65
			"squat":
				p_draw_y += 26.0
				squash = Vector2(1.25, 0.68)
			"balance":
				squash = Vector2(1.12, 0.95)
				p_rot = sin(time_elapsed * 8.0) * 0.18
			"wobble":
				waddle = sin(time_elapsed * 18.0) * 0.45
				p_rot = waddle
			"reach":
				p_draw_y -= 25.0
				squash = Vector2(0.9, 1.15)
			"dizzy":
				p_rot = sin(time_elapsed * 6.0) * 0.3

		penguin_sprite.position = Vector2(penguin_x, p_draw_y)
		penguin_sprite.scale = Vector2(0.65, 0.65) * squash
		penguin_sprite.rotation = p_rot if p_rot != 0.0 else waddle

func _collect_item(it: ArcticItem) -> void:
	it.collected = true
	_spawn_collection_sparkle(it.pos, Color(0.35, 0.95, 1.0) if it.item_type == "crystal" else Color(1.0, 0.85, 0.2))
	
	if it.item_type == "crystal":
		crystals_collected += 1
		GameManager.level3_crystals_collected = crystals_collected
		AudioManager.play_sfx("crystal")
	else:
		fish_collected += 1
		GameManager.level3_fish_collected = fish_collected
		AudioManager.play_sfx("fish")
		AudioManager.play_sfx("bubble_pop")
	
	var total := crystals_collected + fish_collected
	hud.set_instruction("💎 Crystals: %d | 🐟 Fish: %d | Total: %d / 10 ⭐" % [crystals_collected, fish_collected, total])
	
	if total >= 10 and not level_finished:
		_trigger_victory()
		return
	
	# Respawn after delay
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		it.collected = false
		it.pos.x = randf_range(180.0, 1100.0)
	)

func _spawn_collection_sparkle(pos: Vector2, col: Color) -> void:
	for i in range(8):
		var spk := Node2D.new()
		spk.position = pos
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0)
		spk.set_meta("vel", vel)
		spk.set_meta("color", col)
		crystals_container.add_child(spk)
		var tw := create_tween()
		tw.tween_property(spk, "position", pos + vel * 0.4, 0.45)
		tw.parallel().tween_property(spk, "scale", Vector2.ZERO, 0.45)
		tw.tween_callback(spk.queue_free)

func _on_pose_detected(gest: String, lean: String, lean_amt: float, hr: bool, ae: bool, sq: bool, _cd: bool) -> void:
	if level_finished or penguin_state in ["wobble", "dizzy"]:
		return

	var now := Time.get_ticks_msec() / 1000.0

	# 1. Lean Left
	if lean == "lean_left" or gest == "lean_left" or lean_amt < -0.06:
		penguin_x = clampf(penguin_x - 22.0, 150.0, 1130.0)
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Leaning Left! Little feet waddling fast!")

	# 2. Lean Right
	elif lean == "lean_right" or gest == "lean_right" or lean_amt > 0.06:
		penguin_x = clampf(penguin_x + 22.0, 150.0, 1130.0)
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Leaning Right! Little feet waddling fast!")

	# 3. Raise Both Hands -> Jump High
	elif hr or gest == "hands_raised":
		if penguin_state != "jump":
			penguin_state = "jump"
			state_timer = 0.65
			AudioManager.play_sfx("jump")
			hud.set_instruction("🐧 Hands Raised! Baby Penguin Jumps High! ❄️")

	# 4. Arms Extended -> Balance Flippers
	elif ae or gest == "arms_extended":
		penguin_state = "balance"
		state_timer = 0.55
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Arms Extended! Flippers balanced with style!")

	# 5. Squat -> Tiny Penguin Pose
	elif sq or gest == "squat":
		penguin_state = "squat"
		state_timer = 0.55
		if (now - last_pose_time) > POSE_COOLDOWN:
			last_pose_time = now
			AudioManager.play_sfx("chirp")
			hud.set_instruction("🐧 Squatting! Adorable Compact Penguin Loaf!")

	# 6. Lean Forward -> Belly Slide
	elif gest == "lean_forward":
		penguin_state = "slide"
		state_timer = 0.85
		penguin_x = clampf(penguin_x + 16.0, 150.0, 1130.0)
		AudioManager.play_sfx("slide")
		hud.set_instruction("🐧 Belly Slide! Sliding across glossy ice!")

func _on_hand_detected(cursor_pos: Vector2, _swipe: String, _waving: bool, _wave_spd: float, reach_up: bool, _open: bool, _fist: bool) -> void:
	if level_finished or penguin_state in ["jump", "slide", "wobble"]:
		return
	if reach_up or cursor_pos.y < 0.22:
		penguin_state = "reach"
		state_timer = 0.55
	if reach_up and penguin_state != "reach" and not level_finished:
		penguin_state = "reach"
		state_timer = 0.65
		AudioManager.play_sfx("chirp")
		hud.set_instruction("🐧 Reaching Upward! Grabbing high crystals in the sky!")

func _check_random_events(_delta: float) -> void:
	if time_elapsed > next_event_time and not level_finished:
		next_event_time = time_elapsed + randf_range(9.0, 14.0)
		var ev_roll := randi() % 4
		match ev_roll:
			0: _trigger_banana_wobble()
			1: _trigger_snowball_chase()
			2: _trigger_penguin_parade()
			3: _trigger_dizzy_penguin()

func _trigger_banana_wobble() -> void:
	penguin_state = "wobble"
	state_timer = 1.6
	AudioManager.play_sfx("chirp")
	hud.set_instruction("🍌 Banana-Foot Wobble! Flippers waving frantically!")

func _trigger_snowball_chase() -> void:
	hud.set_instruction("❄️ Snowball Rolling! A giant snowball rolls past!")
	var snowball := Node2D.new()
	snowball.position = Vector2(0.0, base_y - 12.0)
	obstacle_container.add_child(snowball)
	
	var tw := create_tween()
	tw.tween_property(snowball, "position:x", 1350.0, 2.4)
	tw.tween_callback(snowball.queue_free)

func _trigger_penguin_parade() -> void:
	hud.set_instruction("🐧 PENGUIN PARADE! Cheerful baby penguins waddling by!")
	AudioManager.play_sfx("chirp")
	for i in range(5):
		var parade_p := Node2D.new()
		parade_p.position = Vector2(-80.0 - i * 65.0, base_y + 12.0)
		obstacle_container.add_child(parade_p)
		
		var tw := create_tween()
		tw.tween_property(parade_p, "position:x", 1380.0 + i * 65.0, 3.6)
		tw.tween_callback(parade_p.queue_free)

func _trigger_dizzy_penguin() -> void:
	penguin_state = "dizzy"
	state_timer = 1.8
	AudioManager.play_sfx("chirp")
	hud.set_instruction("💫 Dizzy Penguin! Stars circling cute little head!")

func _trigger_victory() -> void:
	if level_finished:
		return
	level_finished = true
	
	GameManager.level3_crystals_collected = crystals_collected
	GameManager.level3_fish_collected = fish_collected
	var total_items := crystals_collected + fish_collected
	
	hud.set_instruction("FISH, CRYSTALS AND GLORY — YOU DID IT! 🐧💎 (Total: %d) 🏆" % total_items)
	AudioManager.play_sfx("legend_fanfare")
	
	# Glittering icy sparkle celebration
	for i in range(28):
		var spk := Node2D.new()
		spk.position = Vector2(randf_range(120, 1160), randf_range(160, 580))
		crystals_container.add_child(spk)
		var tw_s := create_tween()
		tw_s.tween_property(spk, "scale", Vector2(2.0, 2.0), 0.4)
		tw_s.parallel().tween_property(spk, "modulate:a", 0.0, 0.8)
		tw_s.tween_callback(spk.queue_free)
	
	var tw := create_tween()
	tw.tween_interval(2.8)
	tw.tween_callback(func():
		GameManager.complete_level(3)
		GameManager.load_secret_ending(true)
	)

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	
	var total_items := crystals_collected + fish_collected
	if total_items >= 10:
		_trigger_victory()
	else:
		level_finished = true
		GameManager.level3_crystals_collected = crystals_collected
		GameManager.level3_fish_collected = fish_collected
		hud.set_instruction("TIME'S UP! 🐧 Collectibles: %d / 10. Let's find magic in Surprise Wonderland! 🌈" % total_items)
		AudioManager.play_sfx("chime")
		
		var tw := create_tween()
		tw.tween_interval(2.6)
		tw.tween_callback(func():
			GameManager.load_secret_ending(true)
		)

# ------------------------------------------------------------------------------
# ILLUSTRATED ARCTIC ENVIRONMENT & PENGUIN HERO DRAWING
# ------------------------------------------------------------------------------
func _draw_arctic_canvas() -> void:
	if not arctic_canvas:
		return
		
	# A. Dancing Aurora Borealis Ribbons in Polar Sky
	for a in range(3):
		var a_col := Color(0.18, 0.95, 0.75, 0.22) if a == 0 else Color(0.65, 0.35, 0.95, 0.18)
		var pts := PackedVector2Array()
		for step in range(20):
			var sx := step * 68.0
			var sy := 120.0 + a * 50.0 + sin(time_elapsed * 1.5 + step * 0.35 + a) * 45.0
			pts.append(Vector2(sx, sy))
		for i in range(pts.size() - 1):
			arctic_canvas.draw_line(pts[i], pts[i+1], a_col, 28.0)

	# B. Active Floating Crystals & Ice Fish (Upgraded Faceted Crystals & Detailed Arctic Fish)
	for it in active_items:
		if not it.collected:
			var ip := it.pos
			if it.item_type == "crystal":
				var float_y := sin(time_elapsed * 3.5 + it.id * 1.5) * 6.0
				var cp := ip + Vector2(0, float_y)
				# 1. Soft pulsing glow halos
				var glow_pulse := 0.20 + sin(time_elapsed * 4.0 + it.id) * 0.08
				arctic_canvas.draw_circle(cp, 30.0, Color(0.25, 0.85, 1.0, glow_pulse))
				arctic_canvas.draw_circle(cp, 20.0, Color(0.70, 0.40, 1.0, glow_pulse * 0.8))
				# 2. Faceted 3D diamond geometry
				var top_v := cp + Vector2(0, -25)
				var left_v := cp + Vector2(-16, -3)
				var right_v := cp + Vector2(16, -3)
				var bot_v := cp + Vector2(0, 25)
				var center_v := cp + Vector2(0, -1)
				# Top-Left facet (bright cyan highlight)
				arctic_canvas.draw_polygon(PackedVector2Array([top_v, left_v, center_v]), PackedColorArray([Color(0.72, 0.94, 1.0, 0.96)]))
				# Top-Right facet (shimmering white/cyan)
				arctic_canvas.draw_polygon(PackedVector2Array([top_v, right_v, center_v]), PackedColorArray([Color(0.90, 0.98, 1.0, 0.96)]))
				# Bottom-Left facet (deep rich azure)
				arctic_canvas.draw_polygon(PackedVector2Array([bot_v, left_v, center_v]), PackedColorArray([Color(0.20, 0.72, 0.98, 0.94)]))
				# Bottom-Right facet (magical amethyst/purple shimmer)
				arctic_canvas.draw_polygon(PackedVector2Array([bot_v, right_v, center_v]), PackedColorArray([Color(0.58, 0.38, 0.95, 0.92)]))
				# Facet edge seams
				var seam_col := Color(1.0, 1.0, 1.0, 0.85)
				arctic_canvas.draw_line(top_v, bot_v, seam_col, 1.5)
				arctic_canvas.draw_line(left_v, right_v, seam_col, 1.5)
				arctic_canvas.draw_line(top_v, left_v, seam_col, 1.5)
				arctic_canvas.draw_line(top_v, right_v, seam_col, 1.5)
				arctic_canvas.draw_line(bot_v, left_v, seam_col, 1.5)
				arctic_canvas.draw_line(bot_v, right_v, seam_col, 1.5)
				# Core twinkle sparkle
				arctic_canvas.draw_circle(cp + Vector2(-2, -6), 3.2, Color.WHITE)
				arctic_canvas.draw_line(cp + Vector2(-7, -6), cp + Vector2(3, -6), Color(1, 1, 1, 0.8), 1.2)
				arctic_canvas.draw_line(cp + Vector2(-2, -11), cp + Vector2(-2, -1), Color(1, 1, 1, 0.8), 1.2)
			else:
				# Detailed Arctic Ice Fish
				var swim_y := sin(time_elapsed * 4.2 + it.id * 2.0) * 4.5
				var fp := ip + Vector2(0, swim_y)
				var tail_wag := sin(time_elapsed * 8.5 + it.id) * 3.5
				# Soft swimming aura
				arctic_canvas.draw_circle(fp, 26.0, Color(0.35, 0.80, 1.0, 0.16))
				# Dorsal fin
				arctic_canvas.draw_polygon(PackedVector2Array([
					fp + Vector2(-4, -10), fp + Vector2(6, -20), fp + Vector2(12, -9)
				]), PackedColorArray([Color(0.28, 0.65, 0.95, 0.85)]))
				# Forked caudal tail fin with animated wag
				arctic_canvas.draw_polygon(PackedVector2Array([
					fp + Vector2(16, 0),
					fp + Vector2(32, -13 + tail_wag),
					fp + Vector2(25, 0 + tail_wag * 0.4),
					fp + Vector2(32, 13 + tail_wag)
				]), PackedColorArray([Color(0.32, 0.70, 0.96, 0.95)]))
				# Fish body (silver-blue back with shimmering belly)
				arctic_canvas.draw_ellipse(fp, 24.0, 13.0, Color(0.28, 0.62, 0.95))
				arctic_canvas.draw_ellipse(fp + Vector2(0, 3), 20.0, 8.0, Color(0.85, 0.95, 1.0, 0.85))
				# Coral/salmon pectoral fin
				arctic_canvas.draw_polygon(PackedVector2Array([
					fp + Vector2(-2, 3), fp + Vector2(7, 13), fp + Vector2(13, 5)
				]), PackedColorArray([Color(1.0, 0.55, 0.45, 0.90)]))
				# Curved gill arch
				arctic_canvas.draw_arc(fp + Vector2(-6, 0), 8.0, -1.2, 1.2, 8, Color(0.18, 0.45, 0.78, 0.75), 1.8)
				# Expressive eye
				arctic_canvas.draw_circle(fp + Vector2(-14, -3), 4.5, Color.WHITE)
				arctic_canvas.draw_circle(fp + Vector2(-15, -3), 2.5, Color(0.08, 0.12, 0.18))
				arctic_canvas.draw_circle(fp + Vector2(-16, -4.2), 1.2, Color.WHITE)

	# C. Rolling Snowball or Parade Penguins Obstacles
	for obs in obstacle_container.get_children():
		arctic_canvas.draw_circle(obs.position, 28.0, Color(0.95, 0.98, 1.0))
		arctic_canvas.draw_arc(obs.position, 28.0, 0, TAU, 16, Color(0.65, 0.8, 0.95), 3.0)

	# D. Snow Movement Puffs
	for sp in snow_puffs:
		arctic_canvas.draw_circle(sp["pos"], sp["radius"], Color(1.0, 1.0, 1.0, sp["alpha"]))
		arctic_canvas.draw_circle(sp["pos"], sp["radius"] * 0.5, Color(0.9, 0.95, 1.0, sp["alpha"] * 0.7))

	# E. Soft Contact Shadow & Dizzy Stars for the Cute Penguin Hero
	var p_draw_y := base_y
	var shadow_y := base_y + 105.0
	var shadow_rx := 50.0
	var shadow_ry := 16.0
	var shadow_alpha := 0.40

	if penguin_state == "jump":
		p_draw_y -= 110.0
		shadow_rx = 32.0
		shadow_ry = 10.0
		shadow_alpha = 0.18
	elif penguin_state == "slide":
		p_draw_y += 24.0
		shadow_rx = 68.0
		shadow_ry = 15.0
	elif penguin_state == "squat":
		p_draw_y += 26.0
		shadow_rx = 58.0
		shadow_ry = 18.0

	# Ground contact shadow beneath feet
	arctic_canvas.draw_ellipse(Vector2(penguin_x, shadow_y), shadow_rx, shadow_ry, Color(0.08, 0.12, 0.22, shadow_alpha))

	# Dizzy stars
	if penguin_state == "dizzy":
		for s in range(3):
			var a := time_elapsed * 5.0 + s * (TAU / 3.0)
			var star_pos := Vector2(penguin_x + cos(a) * 36.0, p_draw_y - 88.0 + sin(a) * 12.0)
			arctic_canvas.draw_circle(star_pos, 5.0, Color(1.0, 0.9, 0.2))
