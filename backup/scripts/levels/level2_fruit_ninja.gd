extends Node2D

## WIGGLE WARS! — Level 2: Fruit Ninja 🍉
## Tropical Fruit-Slicing Arena
## Slices flying fruits with real hand swipes, combos, hazards, and special events:
## Watermelon Fountain, Banana Split, and Sus Strawberry!

@onready var hud: CanvasLayer = $HUD
@onready var fruit_container: Node2D = $FruitContainer
@onready var splash_container: Node2D = $SplashContainer
@onready var blade_trail: Line2D = $BladeTrail

class ActiveFruit:
	var id: int
	var node: Node2D
	var type: String # watermelon, banana, strawberry, apple, orange, bomb, rotten
	var is_special: bool = false
	var velocity: Vector2
	var gravity: float = 850.0
	var is_sliced: bool = false
	var radius: float = 35.0

var fruits: Array[ActiveFruit] = []
var next_fruit_id: int = 1
var spawn_timer: float = 0.0
var level_time: float = 0.0
var level_finished: bool = false

var current_combo: int = 0
var last_slice_time: float = 0.0
const COMBO_WINDOW: float = 0.65

# Swipe trail state
var trail_points: Array[Vector2] = []
var hand_cursor: Vector2 = Vector2(0.5, 0.5)

func _ready() -> void:
	hud.setup_hud("Level 2: Fruit Ninja 🍉", "Swipe your hand through the air to slice fruit!")
	GestureListener.hand_detected.connect(_on_hand_detected)
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level2.wav",
		"Time for Fruit Ninja! Swipe your hands through the air to slice the flying tropical fruit!", 6.0)

func _process(delta: float) -> void:
	if level_finished:
		return
		
	level_time += delta
	spawn_timer += delta
	
	# Spawn regular and special fruit waves
	if spawn_timer >= 1.2:
		spawn_timer = 0.0
		_spawn_random_fruit()
	
	_update_fruits(delta)
	_update_blade_trail(delta)
	queue_redraw()

func _update_fruits(delta: float) -> void:
	var to_remove: Array[ActiveFruit] = []
	for f in fruits:
		if not f.is_sliced:
			f.velocity.y += f.gravity * delta
			f.node.position += f.velocity * delta
			f.node.rotation += delta * 3.0
			
			# Fall off screen
			if f.node.position.y > 780.0:
				to_remove.append(f)
		else:
			# Fading or split pieces
			f.node.modulate.a -= delta * 2.0
			if f.node.modulate.a <= 0.0:
				to_remove.append(f)

	for r in to_remove:
		fruits.erase(r)
		r.node.queue_free()

	# Check level target
	if GameManager.level_scores.get(2, 0) >= 120 and not level_finished:
		level_finished = true
		hud.set_instruction("TROPICAL ARENA CONQUERED! Slice Master!")
		AudioManager.play_sfx("combo")
		
		var tw := create_tween()
		tw.tween_interval(2.0)
		tw.tween_callback(func():
			GameManager.complete_level(2)
			get_tree().change_scene_to_file("res://scenes/level_results.tscn")
		)

func _on_hand_detected(cursor_pos: Vector2, swipe: String, _waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	var screen_pos := Vector2(cursor_pos.x * 1280.0, cursor_pos.y * 720.0)
	hand_cursor = screen_pos
	trail_points.append(screen_pos)
	if trail_points.size() > 10:
		trail_points.remove_at(0)
	
	# Check slice on actual swipe event OR fast movement
	if swipe != "none" or (trail_points.size() >= 2 and (trail_points[-1] - trail_points[-2]).length() > 25.0):
		_perform_slice(screen_pos, 75.0)

func _perform_slice(slice_pos: Vector2, slice_radius: float) -> void:
	AudioManager.play_sfx("swish")
	var hit_count := 0
	
	for f in fruits:
		if f.is_sliced:
			continue
		var dist := f.node.position.distance_to(slice_pos)
		if dist <= (f.radius + slice_radius):
			f.is_sliced = true
			hit_count += 1
			_handle_fruit_sliced(f)

	if hit_count > 0:
		var now := Time.get_ticks_msec() / 1000.0
		if (now - last_slice_time) <= COMBO_WINDOW:
			current_combo += hit_count
		else:
			current_combo = hit_count
		last_slice_time = now
		
		if current_combo > 1:
			var bonus := current_combo * 5
			GameManager.add_score(bonus)
			hud.set_instruction("COMBO x%d! (+%d Bonus!)" % [current_combo, bonus])
			AudioManager.play_sfx("combo")

func _handle_fruit_sliced(f: ActiveFruit) -> void:
	match f.type:
		"bomb":
			AudioManager.play_sfx("bomb")
			GameManager.add_score(0)
			hud.set_instruction("⚠️ BOOM! Hazard Bomb hit! -10 Points!")
			GameManager.total_score = maxi(0, GameManager.total_score - 10)
			GameManager.level_scores[2] = maxi(0, GameManager.level_scores[2] - 10)
			_spawn_splash(f.node.position, Color(0.1, 0.1, 0.1), 1.5)
		"rotten":
			AudioManager.play_sfx("splash")
			hud.set_instruction("🤢 Moldy Rotten Fruit! -5 Points!")
			GameManager.total_score = maxi(0, GameManager.total_score - 5)
			GameManager.level_scores[2] = maxi(0, GameManager.level_scores[2] - 5)
			_spawn_splash(f.node.position, Color(0.4, 0.45, 0.2), 1.0)
		"watermelon_fountain":
			AudioManager.play_sfx("splash")
			GameManager.add_score(25)
			hud.set_instruction("🍉 WATERMELON FOUNTAIN BURST! (+25) Huge Splash!")
			_spawn_splash(f.node.position, Color(0.9, 0.1, 0.2), 2.5)
		"banana_split":
			AudioManager.play_sfx("splash")
			GameManager.add_score(20)
			hud.set_instruction("🍌 BANANA SPLIT BONUS! (+20)")
			_spawn_splash(f.node.position, Color(1.0, 0.9, 0.1), 1.8)
		"sus_strawberry":
			AudioManager.play_sfx("splash")
			GameManager.add_score(20)
			hud.set_instruction("🍓 SUS STRAWBERRY SLICED! Funny comic reaction! (+20)")
			_spawn_splash(f.node.position, Color(1.0, 0.2, 0.4), 1.8)
		_:
			AudioManager.play_sfx("splash")
			GameManager.add_score(10)
			hud.set_instruction("Juicy Slice! (+10)")
			_spawn_splash(f.node.position, Color(1.0, 0.5, 0.1), 1.2)

func _spawn_random_fruit() -> void:
	var roll := randf()
	var f := ActiveFruit.new()
	f.id = next_fruit_id
	next_fruit_id += 1
	
	var node := Node2D.new()
	var start_x := randf_range(200.0, 1080.0)
	node.position = Vector2(start_x, 720.0)
	
	# Initial upward velocity with lateral drift
	var vel_x := randf_range(-180.0, 180.0)
	var vel_y := randf_range(-750.0, -920.0)
	f.velocity = Vector2(vel_x, vel_y)
	
	if roll < 0.12:
		f.type = "watermelon_fountain"
		f.radius = 55.0
		f.is_special = true
	elif roll < 0.24:
		f.type = "banana_split"
		f.radius = 35.0
		f.is_special = true
	elif roll < 0.36:
		f.type = "sus_strawberry"
		f.radius = 35.0
		f.is_special = true
	elif roll < 0.48:
		f.type = "bomb"
		f.radius = 35.0
	elif roll < 0.58:
		f.type = "rotten"
		f.radius = 30.0
	else:
		f.type = "fruit"
		f.radius = 35.0

	f.node = node
	node.set_meta("type", f.type)
	fruit_container.add_child(node)
	fruits.append(f)

func _spawn_splash(pos: Vector2, col: Color, scale_mult: float) -> void:
	for i in range(16):
		var drop := Node2D.new()
		drop.position = pos
		drop.set_meta("vel", Vector2.from_angle(randf() * TAU) * randf_range(120.0, 340.0) * scale_mult)
		drop.set_meta("color", col)
		drop.set_meta("life", 0.6)
		splash_container.add_child(drop)
		
		var tw := create_tween()
		var vel: Vector2 = drop.get_meta("vel")
		var target: Vector2 = pos + vel * 0.5
		tw.tween_property(drop, "position", target, 0.5)
		tw.parallel().tween_property(drop, "scale", Vector2.ZERO, 0.5)
		tw.tween_callback(drop.queue_free)

func _update_blade_trail(_delta: float) -> void:
	blade_trail.clear_points()
	for pt in trail_points:
		blade_trail.add_point(pt)

func _draw() -> void:
	# Draw active fruits procedurally
	for f in fruits:
		if f.is_sliced:
			continue
		var p := f.node.position
		match f.type:
			"watermelon_fountain":
				# Large green and pink melon
				draw_circle(p, 50.0, Color(0.1, 0.65, 0.25))
				draw_circle(p, 42.0, Color(0.95, 0.2, 0.35))
				draw_string(ThemeDB.fallback_font, p + Vector2(-25, 6), "🍉 SPECIAL", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
			"banana_split":
				draw_arc(p, 36.0, -0.4, 1.8, 16, Color(1.0, 0.88, 0.2), 16.0)
				draw_string(ThemeDB.fallback_font, p + Vector2(-20, 6), "🍌 SPLIT", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.BLACK)
			"sus_strawberry":
				# Red strawberry with silly eyes
				draw_polygon(PackedVector2Array([p + Vector2(0, 35), p + Vector2(-30, -20), p + Vector2(30, -20)]), PackedColorArray([Color(0.9, 0.1, 0.2)]))
				# Sus eyes
				draw_circle(p + Vector2(-8, -10), 6.0, Color.WHITE)
				draw_circle(p + Vector2(8, -10), 6.0, Color.WHITE)
				draw_circle(p + Vector2(-6, -10), 3.0, Color.BLACK)
				draw_circle(p + Vector2(6, -10), 3.0, Color.BLACK)
			"bomb":
				# Black spiked bomb with fuse
				draw_circle(p, 32.0, Color(0.15, 0.15, 0.15))
				draw_circle(p + Vector2(0, -32), 6.0, Color(0.9, 0.6, 0.1))
				draw_string(ThemeDB.fallback_font, p + Vector2(-15, 6), "💣 BOMB", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.RED)
			"rotten":
				# Moldy brown fruit
				draw_circle(p, 30.0, Color(0.35, 0.38, 0.2))
				draw_string(ThemeDB.fallback_font, p + Vector2(-15, 5), "🤢 MOLD", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.8, 0.9, 0.4))
			_:
				# Standard orange / apple
				draw_circle(p, 32.0, Color(1.0, 0.55, 0.1))
				draw_circle(p + Vector2(-8, -8), 8.0, Color(1.0, 0.7, 0.3))
