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
@onready var shinchan_timer_label: Label = get_node_or_null("BombLossOverlay/Card/Margin/HBox/VBox/CountdownLabel")
@onready var big_countdown_label: Label = get_node_or_null("CountdownLayer/CenterBox/BigCountdownLabel")

var bombs_cut: int = 0
const MAX_BOMBS_BEFORE_LOSS: int = 4
var last_bomb_slice_time: float = -1.0
var last_countdown_sec: int = -1
var shinchan_challenge_active: bool = false
var shinchan_timer: float = 25.0
var shinchan_concluded: bool = false

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

# 30-Second Level Timer
var time_remaining: float = 30.0
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
	bombs_cut = 0
	time_remaining = 30.0
	shinchan_challenge_active = false
	shinchan_concluded = false
	shinchan_timer = 25.0
	GameManager.level1_fruits_sliced = 0
	GameManager.level1_fruit_score = 0
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
		"Time for Fruit Ninja! Swipe your hands through the air to slice the flying tropical fruit for the next 30 seconds!", 5.5)

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
	
	# Shin Chan Challenge 25s Countdown
	if shinchan_challenge_active and not shinchan_concluded:
		shinchan_timer = maxf(0.0, shinchan_timer - delta)
		if shinchan_timer_label:
			shinchan_timer_label.text = "⏳ Time Remaining: %.1f seconds" % shinchan_timer
		if shinchan_timer <= 0.0:
			_conclude_shinchan_challenge(false)

	# 30-Second Level Timer & 10s Countdown
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		
		if time_remaining <= 10.0 and time_remaining > 0.0:
			var cur_sec := int(ceil(time_remaining))
			if cur_sec in range(1, 11) and cur_sec != last_countdown_sec:
				last_countdown_sec = cur_sec
				if big_countdown_label:
					big_countdown_label.text = str(cur_sec)
					big_countdown_label.visible = true
					big_countdown_label.scale = Vector2(1.4, 1.4)
					var tw_cd := create_tween()
					tw_cd.tween_property(big_countdown_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					AudioManager.play_sfx("chime")
		else:
			if big_countdown_label:
				big_countdown_label.visible = false
				
		if time_remaining <= 0.0:
			if big_countdown_label:
				big_countdown_label.visible = false
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
	# Responsive slicing: requires intentional motion or active swipe
	# Prevents stationary hands from continuously slicing passing fruits
	if swipe != "none" or move_dist > 18.0:
		_perform_slice_segment(prev_pos, screen_pos, 105.0)

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
		var now_t := Time.get_ticks_msec() / 1000.0
		if (now_t - last_bomb_slice_time) > 0.35:
			last_bomb_slice_time = now_t
			bombs_cut += 1
			_spawn_playful_firecracker(f.pos)
			AudioManager.play_sfx("bomb")
			if bombs_cut < MAX_BOMBS_BEFORE_LOSS:
				hud.set_instruction("💥 BOMB CUT! (%d/4) Careful! 4th bomb causes loss!" % bombs_cut)
			else:
				hud.set_instruction("💥 4TH BOMB CUT! Shinchan arrives with a challenge!")
				_trigger_bomb_loss(f.pos)
		else:
			# Visual spark for overlapping segment without double-counting bomb cut
			_spawn_playful_firecracker(f.pos)
	else:
		fruits_sliced += 1
		GameManager.level1_fruits_sliced = fruits_sliced
		GameManager.level1_fruit_score = fruits_sliced * 10
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
	shinchan_challenge_active = true
	shinchan_timer = 25.0
	shinchan_concluded = false
	_spawn_playful_firecracker(pos)
	AudioManager.play_sfx("bomb")
	hud.set_instruction("💥 4TH BOMB HIT! Shinchan arrives with a challenge!")
	
	if bomb_loss_overlay:
		bomb_loss_overlay.visible = true
	if shinchan_timer_label:
		shinchan_timer_label.text = "⏳ Time Remaining: 25.0s"
		
	# Play authentic Tamil dialogue
	AudioManager.play_voice_file("res://assets/audio/Shin Chan Chuti Paiyan Dialogue.mp3",
		"Shinchan: 'Chutti Paiyan!'", 5.0)
		
	if bubble_text:
		bubble_text.text = "Shinchan: \"Chutti Paiyan! Repeat after me into your microphone! 🗣️\""
	if speech_status_label:
		speech_status_label.text = "Listening to microphone... Say 'Chutti Paiyan'!"
		
	# Request genuine microphone speech recognition
	GestureListener.request_speech_recognition()

func _on_speech_status(_status: String, message: String) -> void:
	if speech_status_label:
		speech_status_label.text = message

func _on_speech_result(success: bool, text: String, _audio_file: String) -> void:
	if shinchan_concluded:
		return
	if success and text != "":
		var t_lower := text.to_lower()
		if "chut" in t_lower or "pai" in t_lower or "pay" in t_lower or "shin" in t_lower or "cutie" in t_lower:
			if speech_status_label:
				speech_status_label.text = "Shinchan heard: '%s'! ✔ Dialogue matched!" % text
			_conclude_shinchan_challenge(true)
		else:
			if speech_status_label:
				speech_status_label.text = "Heard '%s'. Repeat 'Chutti Paiyan'!" % text
			AudioManager.play_sfx("chime")
	else:
		if speech_status_label:
			speech_status_label.text = "Microphone ready. Tap 'Speak to Shinchan' to repeat!"

func _conclude_shinchan_challenge(won: bool) -> void:
	if shinchan_concluded:
		return
	shinchan_concluded = true
	if won:
		if bubble_text:
			bubble_text.text = "YOU WON THE CHALLENGE! 🎉\nShinchan: \"Wahaha! Spot on! Off to Surprise Wonderland! 🌈\""
		if speech_status_label:
			speech_status_label.text = "Challenge Won! Transitioning to Surprise Wonderland..."
		AudioManager.play_sfx("combo")
	else:
		if bubble_text:
			bubble_text.text = "GREAT TRY! EVERY ATTEMPT MAKES YOU BETTER! 💗\nShinchan: \"Keep smiling and shining! Off to Wonderland! 🌸\""
		if speech_status_label:
			speech_status_label.text = "Great attempt! Transitioning to Surprise Wonderland..."
		AudioManager.play_sfx("chime")
		
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		GameManager.load_secret_ending(true)
	)

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
	GameManager.load_level(2) # Proceeds to Level 2: Waddle Wars!

func _spawn_playful_firecracker(pos: Vector2) -> void:
	AudioManager.play_sfx("bomb")
	AudioManager.play_sfx("combo")
	hud.set_instruction("✨ PLAYFUL FIRECRACKER BURST! 🎆 Colorful sparks and stars fly!")
	
	# Brief warm playful screen flash
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.7, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	$WorldLayer.add_child(flash)
	var tw_f := create_tween()
	tw_f.tween_property(flash, "color:a", 0.0, 0.25)
	tw_f.tween_callback(flash.queue_free)
	
	# Expanding explosion shockwave rings
	for r_i in range(2):
		var ring := Node2D.new()
		ring.position = pos
		ring.set_meta("is_ring", true)
		ring.set_meta("radius", 25.0)
		ring.set_meta("color", Color(1.0, 0.85, 0.3) if r_i == 0 else Color(1.0, 0.3, 0.6))
		splash_container.add_child(ring)
		var tw_r := create_tween()
		tw_r.tween_property(ring, "scale", Vector2.ZERO, 0.45).from(Vector2.ONE)
		tw_r.parallel().tween_method(func(v: float): ring.set_meta("radius", v), 20.0, 120.0 + r_i * 40.0, 0.45)
		tw_r.tween_callback(ring.queue_free)
	
	# 36 Colorful celebration sparks (star-shaped firecracker particles)
	var colors := [
		Color(1.0, 0.85, 0.2), # Gold
		Color(1.0, 0.25, 0.75), # Neon Magenta
		Color(0.2, 0.95, 0.9), # Turquoise
		Color(0.4, 1.0, 0.3), # Lime
		Color(1.0, 0.5, 0.1), # Bright Orange
		Color(0.8, 0.4, 1.0) # Violet
	]
	for i in range(36):
		var spark := Node2D.new()
		spark.position = pos
		var angle := randf() * TAU
		var spd := randf_range(160.0, 520.0)
		var vel := Vector2.from_angle(angle) * spd
		spark.set_meta("vel", vel)
		spark.set_meta("color", colors[i % colors.size()])
		spark.set_meta("is_star", true)
		spark.set_meta("rot", randf() * TAU)
		spark.set_meta("rot_spd", randf_range(-8.0, 8.0))
		splash_container.add_child(spark)
		
		var tw := create_tween()
		var target := pos + vel * randf_range(0.45, 0.75)
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

	# G. Active Splash Drops & Colorful Firecracker Stars / Shockwave Rings
	for s in splash_container.get_children():
		var col: Color = s.get_meta("color", Color.ORANGE)
		var sc: float = s.scale.x
		if s.get_meta("is_ring", false):
			var r_rad: float = s.get_meta("radius", 25.0)
			arena_canvas.draw_arc(s.position, r_rad, 0.0, TAU, 28, Color(col.r, col.g, col.b, sc * 0.9), 4.5 * sc)
			arena_canvas.draw_arc(s.position, r_rad * 0.85, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, sc * 0.7), 2.5 * sc)
		elif s.get_meta("is_star", false):
			var star_r := 14.0 * sc
			var rot: float = s.get_meta("rot", 0.0) + time_elapsed * s.get_meta("rot_spd", 4.0)
			var star_pts := PackedVector2Array()
			for pt in range(10):
				var a := rot + pt * (PI / 5.0)
				var r := star_r if (pt % 2 == 0) else (star_r * 0.42)
				star_pts.append(s.position + Vector2(cos(a), sin(a)) * r)
			arena_canvas.draw_colored_polygon(star_pts, col)
			arena_canvas.draw_circle(s.position, star_r * 0.35, Color.WHITE)
			arena_canvas.draw_circle(s.position, star_r * 1.6, Color(col.r, col.g, col.b, 0.3 * sc))
		else:
			arena_canvas.draw_circle(s.position, 7.0 * sc, col)
			arena_canvas.draw_circle(s.position, 12.0 * sc, Color(col.r, col.g, col.b, 0.35))

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
