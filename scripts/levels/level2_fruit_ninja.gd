extends Node2D

## WIGGLE WARS! — Level 2: Fruit Ninja 🍉
## Fully Illustrated Tropical Fruit Arena
## Spawns flying tropical fruits repeatedly across a 60-second timer.
## Detects hand swipes, slices intersecting fruits into tumbling halves with juicy splashes.
## Score system completely removed per design requirement.

@onready var hud: CanvasLayer = $HUD
@onready var arena_canvas: Node2D = $WorldLayer/ArenaCanvas
@onready var fruit_container: Node2D = $WorldLayer/FruitContainer
@onready var splash_container: Node2D = $WorldLayer/SplashContainer
@onready var blade_trail: Line2D = $WorldLayer/BladeTrail

@onready var victory_overlay: CanvasLayer = get_node_or_null("VictoryOverlay")
@onready var victory_score_label: Label = get_node_or_null("VictoryOverlay/Card/Margin/VBox/ScoreLabel")
@onready var victory_continue_btn: Button = get_node_or_null("VictoryOverlay/Card/Margin/VBox/ContinueBtn")

@onready var bomb_loss_overlay: CanvasLayer = get_node_or_null("BombLossOverlay")
@onready var bubble_text: Label = get_node_or_null("BombLossOverlay/Card/Margin/HBox/VBox/DialogueBubble/Margin/BubbleText")
@onready var speech_status_label: Label = get_node_or_null("BombLossOverlay/Card/Margin/HBox/VBox/StatusLabel")
@onready var speak_btn: Button = get_node_or_null("BombLossOverlay/Card/Margin/HBox/VBox/SpeakBtn")
@onready var wonderland_btn: Button = get_node_or_null("BombLossOverlay/Card/Margin/HBox/VBox/WonderlandBtn")

class ActiveFruit:
	var id: int
	var type: String # watermelon, banana, strawberry, apple, orange, pineapple, bomb
	var pos: Vector2
	var velocity: Vector2
	var gravity: float = 850.0
	var rotation: float = 0.0
	var rot_speed: float = 3.0
	var is_sliced: bool = false
	var radius: float = 38.0
	var slice_time: float = 0.0
	# Half pieces if sliced
	var half_l_pos: Vector2
	var half_r_pos: Vector2
	var half_l_vel: Vector2
	var half_r_vel: Vector2

var fruits: Array[ActiveFruit] = []
var next_fruit_id: int = 1
var spawn_timer: float = 0.0

# 45-Second Level Timer
var time_remaining: float = 45.0
var level_finished: bool = false
var time_elapsed: float = 0.0

# Swipe and slice state
var trail_points: Array[Vector2] = []
var hand_cursor: Vector2 = Vector2(640, 360)
var is_mouse_swiping: bool = false

# Sliced fruits results counter
var fruits_sliced: int = 0

# Decorative tropical props (unwanted windmill palm trees removed for pristine lake view)
var hanging_vines: Array[Dictionary] = []
var floating_neon_fruits: Array[Dictionary] = []

func _ready() -> void:
	fruits_sliced = 0
	GameManager.level2_fruits_sliced = 0
	
	hud.setup_hud("Level 1: Fruit Ninja 🍉", "Swipe your hand through the air to slice the flying tropical fruit!")
	hud.set_timer(time_remaining)
	
	if victory_overlay:
		victory_overlay.visible = false
	if bomb_loss_overlay:
		bomb_loss_overlay.visible = false
		
	if victory_continue_btn:
		victory_continue_btn.pressed.connect(_on_victory_continue_pressed)
	if speak_btn:
		speak_btn.pressed.connect(_on_speak_btn_pressed)
	if wonderland_btn:
		wonderland_btn.pressed.connect(_on_wonderland_pressed)
		
	GestureListener.hand_detected.connect(_on_hand_detected)
	GestureListener.speech_result.connect(_on_speech_result)
	GestureListener.speech_status.connect(_on_speech_status)
	
	if arena_canvas:
		arena_canvas.draw.connect(_draw_arena_canvas)
		
	_init_tropical_scenery()
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level2.wav",
		"Time for Fruit Ninja! Swipe your hands through the air to slice the flying tropical fruit for the next 45 seconds!", 6.0)

func _init_tropical_scenery() -> void:
	
	hanging_vines.clear()
	for i in range(8):
		hanging_vines.append({
			"x": 80.0 + i * 160.0 + randf_range(-30, 30),
			"length": randf_range(110.0, 220.0),
			"sway_spd": randf_range(1.5, 2.5),
			"phase": randf() * TAU
		})

	# Floating neon fruit silhouettes drifting in the arcade background
	floating_neon_fruits.clear()
	var neon_palette := [
		Color(0.08, 0.95, 0.85, 0.28), # Electric Turquoise
		Color(1.0, 0.22, 0.72, 0.28),  # Neon Pink / Magenta
		Color(0.45, 1.0, 0.25, 0.24),  # Neon Lime
		Color(1.0, 0.85, 0.15, 0.26)   # Neon Gold
	]
	var types := ["watermelon", "citrus", "berry", "star"]
	for i in range(14):
		floating_neon_fruits.append({
			"pos": Vector2(randf_range(40, 1240), randf_range(60, 500)),
			"speed": Vector2(randf_range(-15.0, 15.0), randf_range(-8.0, 8.0)),
			"rot": randf() * TAU,
			"rot_speed": randf_range(-0.6, 0.6),
			"type": types[randi() % types.size()],
			"color": neon_palette[randi() % neon_palette.size()],
			"scale": randf_range(0.8, 1.4)
		})

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 60-Second Level Timer
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		if time_remaining <= 0.0:
			_on_level_timer_complete()
	
	if not level_finished:
		spawn_timer += delta
		# Continuous fruit waves throughout gameplay
		if spawn_timer >= 1.05:
			spawn_timer = 0.0
			_spawn_fruit_wave()
			
	# Drift background neon fruits with wrap-around
	for nf in floating_neon_fruits:
		nf["pos"] += nf["speed"] * delta
		nf["rot"] += nf["rot_speed"] * delta
		if nf["pos"].x < -80.0:
			nf["pos"].x = 1360.0
		elif nf["pos"].x > 1360.0:
			nf["pos"].x = -80.0
		if nf["pos"].y < 40.0:
			nf["pos"].y = 540.0
		elif nf["pos"].y > 540.0:
			nf["pos"].y = 40.0

	_update_fruits(delta)
	_update_blade_trail()
	
	if arena_canvas:
		arena_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if level_finished:
		return
		
	# Mouse / Touch fallback support
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_swiping = event.pressed
			if event.pressed:
				hand_cursor = event.position
				_add_trail_point(event.position)
				_perform_slice(event.position, 55.0)
	elif event is InputEventMouseMotion:
		var prev_pos := hand_cursor
		hand_cursor = event.position
		_add_trail_point(event.position)
		if is_mouse_swiping or event.velocity.length() > 180.0:
			_perform_slice_segment(prev_pos, event.position, 65.0)
		else:
			_perform_slice(event.position, 45.0)

func _on_hand_detected(cursor_pos: Vector2, swipe: String, _waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	if level_finished:
		return
		
	var screen_pos := Vector2(cursor_pos.x * 1280.0, cursor_pos.y * 720.0)
	var prev_pos := hand_cursor
	hand_cursor = screen_pos
	_add_trail_point(screen_pos)
	
	var move_dist := (screen_pos - prev_pos).length()
	if swipe != "none" or move_dist > 14.0:
		_perform_slice_segment(prev_pos, screen_pos, 105.0)
	else:
		_perform_slice(screen_pos, 85.0)

func _add_trail_point(pos: Vector2) -> void:
	trail_points.append(pos)
	if trail_points.size() > 12:
		trail_points.remove_at(0)

func _update_blade_trail() -> void:
	if not blade_trail:
		return
	blade_trail.clear_points()
	for pt in trail_points:
		blade_trail.add_point(pt)

func _spawn_fruit_wave() -> void:
	var count := randi_range(1, 3)
	for i in range(count):
		_spawn_single_fruit()

func _spawn_single_fruit() -> void:
	var f := ActiveFruit.new()
	f.id = next_fruit_id
	next_fruit_id += 1
	
	var start_x := randf_range(220.0, 1060.0)
	f.pos = Vector2(start_x, 720.0)
	
	var vel_x := randf_range(-190.0, 190.0)
	var vel_y := randf_range(-760.0, -940.0)
	f.velocity = Vector2(vel_x, vel_y)
	f.rot_speed = randf_range(-4.0, 4.0)
	
	var roll := randf()
	if roll < 0.15:
		f.type = "watermelon_fountain"
		f.radius = 52.0
	elif roll < 0.30:
		f.type = "banana_split"
		f.radius = 36.0
	elif roll < 0.45:
		f.type = "sus_strawberry"
		f.radius = 35.0
	elif roll < 0.58:
		f.type = "bomb"
		f.radius = 34.0
	elif roll < 0.75:
		f.type = "pineapple"
		f.radius = 42.0
	elif roll < 0.88:
		f.type = "orange"
		f.radius = 32.0
	else:
		f.type = "apple"
		f.radius = 32.0
		
	f.half_l_pos = f.pos
	f.half_r_pos = f.pos
	fruits.append(f)

func _update_fruits(delta: float) -> void:
	var to_remove: Array[ActiveFruit] = []
	for f in fruits:
		if not f.is_sliced:
			f.velocity.y += f.gravity * delta
			f.pos += f.velocity * delta
			f.rotation += f.rot_speed * delta
			
			if f.pos.y > 780.0:
				to_remove.append(f)
		else:
			# Sliced halves tumbling apart
			f.slice_time += delta
			f.half_l_vel.y += f.gravity * delta
			f.half_r_vel.y += f.gravity * delta
			f.half_l_pos += f.half_l_vel * delta
			f.half_r_pos += f.half_r_vel * delta
			
			if f.slice_time >= 1.2:
				to_remove.append(f)
				
	for r in to_remove:
		fruits.erase(r)

func _perform_slice(slice_pos: Vector2, slice_radius: float) -> void:
	var sliced_any := false
	for f in fruits:
		if f.is_sliced:
			continue
		var dist := f.pos.distance_to(slice_pos)
		if dist <= (f.radius + slice_radius):
			f.is_sliced = true
			sliced_any = true
			_handle_fruit_sliced(f, slice_pos)
			
	if sliced_any:
		AudioManager.play_sfx("swish")

func _perform_slice_segment(p_from: Vector2, p_to: Vector2, slice_radius: float) -> void:
	var sliced_any := false
	for f in fruits:
		if f.is_sliced:
			continue
		var closest_pt := Geometry2D.get_closest_point_to_segment(f.pos, p_from, p_to)
		var dist := f.pos.distance_to(closest_pt)
		if dist <= (f.radius + slice_radius):
			f.is_sliced = true
			sliced_any = true
			_handle_fruit_sliced(f, closest_pt)
			
	if sliced_any:
		AudioManager.play_sfx("swish")

func _handle_fruit_sliced(f: ActiveFruit, slice_origin: Vector2) -> void:
	f.half_l_pos = f.pos
	f.half_r_pos = f.pos
	var angle := slice_origin.angle_to_point(f.pos)
	var norm := Vector2.from_angle(angle + PI / 2)
	f.half_l_vel = f.velocity * 0.5 - norm * 260.0 + Vector2(0, -120)
	f.half_r_vel = f.velocity * 0.5 + norm * 260.0 + Vector2(0, -120)
	
	if f.type == "bomb":
		_trigger_bomb_loss(f.pos)
	else:
		fruits_sliced += 1
		GameManager.level2_fruits_sliced = fruits_sliced
		match f.type:
			"watermelon_fountain":
				AudioManager.play_sfx("splash")
				hud.set_instruction("🍉 WATERMELON FOUNTAIN BURST! Sliced: %d" % fruits_sliced)
				_spawn_splash(f.pos, Color(0.95, 0.15, 0.3), 2.8)
			"banana_split":
				AudioManager.play_sfx("splash")
				hud.set_instruction("🍌 BANANA SPLIT! Sliced: %d" % fruits_sliced)
				_spawn_splash(f.pos, Color(1.0, 0.9, 0.2), 2.0)
			"sus_strawberry":
				AudioManager.play_sfx("splash")
				hud.set_instruction("🍓 SUS STRAWBERRY SLICED! Sliced: %d" % fruits_sliced)
				_spawn_splash(f.pos, Color(1.0, 0.2, 0.4), 2.0)
			"pineapple":
				AudioManager.play_sfx("splash")
				hud.set_instruction("🍍 Sweet Tropical Pineapple Sliced! Sliced: %d" % fruits_sliced)
				_spawn_splash(f.pos, Color(1.0, 0.8, 0.1), 1.8)
			_:
				AudioManager.play_sfx("splash")
				hud.set_instruction("Juicy Tropical Slice! Sliced: %d 🍉" % fruits_sliced)
				_spawn_splash(f.pos, Color(1.0, 0.55, 0.15), 1.5)

func _trigger_bomb_loss(pos: Vector2) -> void:
	level_finished = true
	_spawn_playful_firecracker(pos)
	AudioManager.play_sfx("bomb")
	hud.set_instruction("💥 PLAYFUL BOMB BURST! Shinchan arrives with a challenge!")
	
	if bomb_loss_overlay:
		bomb_loss_overlay.visible = true
		
	# Play supplied Shin Chan Chutti Paiyan dialogue
	AudioManager.play_voice_file("res://assets/audio/shinchan_chuti_paiyan.mp3",
		"Shinchan: 'Chutti Paiyan!'", 4.0)
		
	if speech_status_label:
		speech_status_label.text = "Listening to microphone... Repeat after Shinchan: 'Chutti Paiyan!'"
		
	# Request genuine microphone speech recognition
	GestureListener.request_speech_recognition()

func _on_speech_status(_status: String, message: String) -> void:
	if speech_status_label:
		speech_status_label.text = message

func _on_speech_result(success: bool, text: String, _audio_file: String) -> void:
	if success and text != "":
		if speech_status_label:
			speech_status_label.text = "Shinchan heard: '%s'! ✔ Speech repeated!" % text
		if bubble_text:
			bubble_text.text = "Shinchan: \"Wahaha! Spot on! You said '%s'! Let's head to Surprise Wonderland! 🌈\"" % text
		AudioManager.play_sfx("combo")
	else:
		if speech_status_label:
			speech_status_label.text = "Microphone checked! Shinchan laughs: 'Good effort, buddy!'"
		if bubble_text:
			bubble_text.text = "Shinchan: \"Hehehe, close enough! Off to Surprise Wonderland we go! 🌈\""
		AudioManager.play_sfx("chime")

func _on_speak_btn_pressed() -> void:
	if speech_status_label:
		speech_status_label.text = "Listening to microphone... Speak clearly into your mic!"
	AudioManager.play_sfx("chime")
	GestureListener.request_speech_recognition()

func _on_wonderland_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.load_secret_ending(true)

func _on_victory_continue_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.complete_level(1)
	GameManager.load_level(2) # Proceeds to Face Frenzy!

func _spawn_playful_firecracker(pos: Vector2) -> void:
	AudioManager.play_sfx("combo")
	AudioManager.play_sfx("chime")
	hud.set_instruction("✨ PLAYFUL FIRECRACKER BURST! 🎆 Confetti & colorful sparks fly!")
	
	# Brief warm playful screen flash
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.7, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	$WorldLayer.add_child(flash)
	var tw_f := create_tween()
	tw_f.tween_property(flash, "color:a", 0.0, 0.25)
	tw_f.tween_callback(flash.queue_free)
	
	# 32 Colorful celebration sparks (firecracker confetti)
	var colors := [
		Color(1.0, 0.85, 0.2), # Gold
		Color(1.0, 0.25, 0.75), # Neon Magenta
		Color(0.2, 0.95, 0.9), # Turquoise
		Color(0.4, 1.0, 0.3), # Lime
		Color(1.0, 0.5, 0.1) # Bright Orange
	]
	for i in range(32):
		var spark := Node2D.new()
		spark.position = pos
		var angle := randf() * TAU
		var spd := randf_range(160.0, 480.0)
		var vel := Vector2.from_angle(angle) * spd
		spark.set_meta("vel", vel)
		spark.set_meta("color", colors[i % colors.size()])
		splash_container.add_child(spark)
		
		var tw := create_tween()
		var target := pos + vel * randf_range(0.45, 0.7)
		tw.tween_property(spark, "position", target, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(spark, "scale", Vector2.ZERO, 0.65)
		tw.tween_callback(spark.queue_free)

func _spawn_splash(pos: Vector2, col: Color, scale_mult: float) -> void:
	for i in range(18):
		var drop := Node2D.new()
		drop.position = pos
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(140.0, 380.0) * scale_mult
		drop.set_meta("vel", vel)
		drop.set_meta("color", col)
		splash_container.add_child(drop)
		
		var tw := create_tween()
		var target := pos + vel * 0.55
		tw.tween_property(drop, "position", target, 0.55)
		tw.parallel().tween_property(drop, "scale", Vector2.ZERO, 0.55)
		tw.tween_callback(drop.queue_free)

func _on_level_timer_complete() -> void:
	if level_finished:
		return
	level_finished = true
	GameManager.level2_fruits_sliced = fruits_sliced
	
	hud.set_instruction("TIME'S UP! 🍉 Total Sliced: %d Tropical Fruits! 🏆" % fruits_sliced)
	AudioManager.play_sfx("legend_fanfare")
	
	if victory_overlay:
		victory_overlay.visible = true
		if victory_score_label:
			victory_score_label.text = "Total Fruits Sliced: %d 🍉" % fruits_sliced

# ------------------------------------------------------------------------------
# ILLUSTRATED TROPICAL ARENA ENVIRONMENT & FRUITS DRAWING
# ------------------------------------------------------------------------------
func _draw_arena_canvas() -> void:
	if not arena_canvas:
		return
		
	# Unwanted blue horizontal and vertical lines completely removed to preserve
	# the pristine illustrated lake view.

	# B. Floating Neon Fruit Silhouettes with Parallax Drift
	for nf in floating_neon_fruits:
		var np: Vector2 = nf["pos"]
		var n_col: Color = nf["color"]
		var n_sc: float = nf["scale"]
		var n_rot: float = nf["rot"]
		var n_type: String = nf["type"]
		
		match n_type:
			"watermelon":
				arena_canvas.draw_arc(np, 26.0 * n_sc, n_rot, n_rot + PI, 14, n_col, 5.0 * n_sc)
				arena_canvas.draw_line(np + Vector2(cos(n_rot), sin(n_rot)) * 26.0 * n_sc,
									   np + Vector2(cos(n_rot + PI), sin(n_rot + PI)) * 26.0 * n_sc, n_col, 4.0 * n_sc)
			"citrus":
				arena_canvas.draw_circle(np, 22.0 * n_sc, Color(n_col.r, n_col.g, n_col.b, 0.12))
				arena_canvas.draw_arc(np, 22.0 * n_sc, 0, TAU, 16, n_col, 3.5 * n_sc)
				for spk in range(4):
					var sa := n_rot + spk * (TAU / 4.0)
					arena_canvas.draw_line(np, np + Vector2(cos(sa), sin(sa)) * 20.0 * n_sc, n_col, 2.0)
			"star":
				for st in range(5):
					var sa := n_rot + st * (TAU / 5.0)
					arena_canvas.draw_circle(np + Vector2(cos(sa), sin(sa)) * 14.0 * n_sc, 3.5 * n_sc, n_col)
			_:
				arena_canvas.draw_circle(np, 16.0 * n_sc, n_col)

	# C. Hanging Glowing Cyber Jungle Vines along Top (Windmill structures removed)
	for v in hanging_vines:
		var vx: float = v["x"]
		var l: float = v["length"]
		var sway := sin(time_elapsed * v["sway_spd"] + v["phase"]) * 14.0
		arena_canvas.draw_line(Vector2(vx, 0), Vector2(vx + sway, l), Color(0.15, 0.95, 0.7, 0.7), 4.0)
		arena_canvas.draw_circle(Vector2(vx + sway, l), 7.0, Color(0.2, 1.0, 0.85, 0.95))

	# E. Sleek Cyber Cutting Platform at Bottom
	var platform_top := 640.0
	arena_canvas.draw_rect(Rect2(0, platform_top, 1280, 80), Color(0.07, 0.04, 0.15))
	arena_canvas.draw_line(Vector2(0, platform_top), Vector2(1280, platform_top), Color(0.1, 0.95, 0.9, 0.95), 6.0)
	arena_canvas.draw_line(Vector2(0, platform_top + 4), Vector2(1280, platform_top + 4), Color(1.0, 0.2, 0.7, 0.7), 2.0)
	for b in range(22):
		var bx := b * 60.0
		arena_canvas.draw_line(Vector2(bx, platform_top), Vector2(bx, 720), Color(0.15, 0.1, 0.3), 3.0)

	# F. Active Flying Fruits with High Contrast
	for f in fruits:
		if not f.is_sliced:
			_draw_single_fruit(f.pos, f.type, f.rotation)
		else:
			_draw_half_fruit(f.half_l_pos, f.type, true)
			_draw_half_fruit(f.half_r_pos, f.type, false)

	# G. Active Splash Drops & Glow Rings
	for s in splash_container.get_children():
		var col: Color = s.get_meta("color", Color.ORANGE)
		arena_canvas.draw_circle(s.position, 7.0 * s.scale.x, col)
		arena_canvas.draw_circle(s.position, 12.0 * s.scale.x, Color(col.r, col.g, col.b, 0.35))

	# H. Glowing Ninja Blade Reticle (Follows Player's Hand)
	if not level_finished and hand_cursor != Vector2.ZERO:
		var pulse := 1.0 + sin(time_elapsed * 10.0) * 0.2
		arena_canvas.draw_circle(hand_cursor, 22.0 * pulse, Color(0.2, 0.95, 1.0, 0.25))
		arena_canvas.draw_arc(hand_cursor, 14.0 * pulse, 0, TAU, 16, Color(1.0, 1.0, 1.0, 0.9), 2.5)
		arena_canvas.draw_circle(hand_cursor, 4.0, Color.WHITE)

func _draw_single_fruit(p: Vector2, type: String, rot: float) -> void:
	match type:
		"watermelon_fountain":
			arena_canvas.draw_circle(p, 48.0, Color(0.12, 0.65, 0.25)) # Dark green rind
			arena_canvas.draw_circle(p, 41.0, Color(0.88, 0.95, 0.8)) # White inner rind
			arena_canvas.draw_circle(p, 36.0, Color(0.95, 0.20, 0.35)) # Deep red flesh
			# Black seeds
			for s in range(5):
				var sa := s * (TAU / 5.0) + rot
				arena_canvas.draw_circle(p + Vector2(cos(sa), sin(sa)) * 20.0, 3.0, Color.BLACK)
		"banana_split":
			arena_canvas.draw_arc(p, 36.0, -0.4 + rot, 1.8 + rot, 16, Color(1.0, 0.88, 0.2), 16.0)
			arena_canvas.draw_circle(p + Vector2(cos(rot), sin(rot)) * 28.0, 5.0, Color(0.35, 0.2, 0.1))
		"sus_strawberry":
			arena_canvas.draw_polygon(PackedVector2Array([
				p + Vector2(0, 35), p + Vector2(-30, -20), p + Vector2(30, -20)
			]), PackedColorArray([Color(0.92, 0.15, 0.25)]))
			# Leaves
			arena_canvas.draw_polygon(PackedVector2Array([
				p + Vector2(0, -32), p + Vector2(-18, -18), p + Vector2(18, -18)
			]), PackedColorArray([Color(0.2, 0.75, 0.3)]))
			# Silly eyes
			arena_canvas.draw_circle(p + Vector2(-9, -8), 7.0, Color.WHITE)
			arena_canvas.draw_circle(p + Vector2(9, -8), 7.0, Color.WHITE)
			arena_canvas.draw_circle(p + Vector2(-7, -8), 3.5, Color.BLACK)
			arena_canvas.draw_circle(p + Vector2(7, -8), 3.5, Color.BLACK)
		"pineapple":
			arena_canvas.draw_ellipse(p, 28.0, 38.0, Color(0.95, 0.72, 0.15))
			# Spiky crown
			arena_canvas.draw_polygon(PackedVector2Array([
				p + Vector2(0, -55), p + Vector2(-22, -32), p + Vector2(22, -32)
			]), PackedColorArray([Color(0.18, 0.65, 0.25)]))
		"bomb":
			arena_canvas.draw_circle(p, 32.0, Color(0.14, 0.14, 0.18))
			arena_canvas.draw_circle(p + Vector2(0, -30), 6.0, Color(0.95, 0.65, 0.1)) # fuse tip
			arena_canvas.draw_line(p + Vector2(0, -24), p + Vector2(0, -30), Color(0.6, 0.45, 0.3), 3.0)
		_:
			# Apple / Orange
			var c := Color(1.0, 0.55, 0.15) if type == "orange" else Color(0.92, 0.2, 0.2)
			arena_canvas.draw_circle(p, 30.0, c)
			arena_canvas.draw_circle(p + Vector2(-8, -8), 7.0, c.lightened(0.3))
			arena_canvas.draw_line(p + Vector2(0, -28), p + Vector2(4, -36), Color(0.4, 0.25, 0.15), 3.0)

func _draw_half_fruit(p: Vector2, type: String, is_left: bool) -> void:
	var offset := -12.0 if is_left else 12.0
	match type:
		"watermelon_fountain":
			arena_canvas.draw_arc(p, 32.0, -PI/2 if is_left else PI/2, PI/2 if is_left else 3*PI/2, 16, Color(0.12, 0.65, 0.25), 10.0)
			arena_canvas.draw_circle(p + Vector2(offset * 0.4, 0), 24.0, Color(0.95, 0.2, 0.35))
		_:
			arena_canvas.draw_circle(p + Vector2(offset * 0.5, 0), 20.0, Color(1.0, 0.7, 0.2))
