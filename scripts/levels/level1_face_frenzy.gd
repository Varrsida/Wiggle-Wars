extends Node2D

## WIGGLE WARS! — Level 1: Face Frenzy 🌸
## Fully Illustrated Magical Expression Garden
## Reacts to 5 independent actions: Smile, Open Mouth, Raise Eyebrows, Sleepy Eyes, Surprised.
## Exactly 60-second session timer. Score system completely removed.

@onready var hud: CanvasLayer = $HUD
@onready var garden_canvas: Node2D = $WorldLayer/GardenCanvas
@onready var bubble_container: Node2D = $WorldLayer/BubbleContainer
@onready var star_container: Node2D = $WorldLayer/StarContainer
@onready var tulip_container: Node2D = $WorldLayer/TulipContainer
@onready var wind_particles: CPUParticles2D = $WorldLayer/WindParticles
@onready var sparkle_particles: CPUParticles2D = $WorldLayer/SparkleParticles

var tulip_tex: Texture2D = preload("res://assets/sprites/tulip_flower.png")

# Objective UI
@onready var objective_panel: PanelContainer = $LevelUI/ObjectivePanel
@onready var obj_smile_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/SmileObj
@onready var obj_mouth_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/MouthObj
@onready var obj_eyebrows_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/EyebrowsObj
@onready var obj_sleepy_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/SleepyObj
@onready var obj_surprised_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/SurprisedObj
@onready var obj_counter_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/Header
@onready var victory_panel: PanelContainer = $LevelUI/VictoryPanel

var completed_actions: Dictionary = {
	"smile": false,
	"mouth_open": false,
	"eyebrows": false,
	"sleepy": false,
	"surprised": false
}

# 60-Second Level Timer
var time_remaining: float = 60.0
var level_finished: bool = false
var time_elapsed: float = 0.0

var last_action_time: float = 0.0
const ACTION_COOLDOWN: float = 0.45 # rapid responsiveness
var is_sleepy_mode: bool = false
var sleepy_timer: float = 0.0

# Rich illustrated objects state
var cloud_data: Array[Dictionary] = []
var butterfly_data: Array[Dictionary] = []
var flower_data: Array[Dictionary] = []
var mushroom_data: Array[Dictionary] = []
var tree_data: Array[Dictionary] = []

func _ready() -> void:
	hud.setup_hud("Level 1: Face Frenzy 🌸", "Make silly faces: Smile, Open Mouth, Raise Brows, Sleepy & Surprised!")
	hud.set_timer(time_remaining)
	
	if victory_panel:
		victory_panel.visible = false
	
	GestureListener.face_detected.connect(_on_face_detected)
	
	if garden_canvas:
		garden_canvas.draw.connect(_draw_garden_canvas)
	
	_init_world_elements()
	_update_objective_ui()
	
	AudioManager.play_music_procedural("garden")
	AudioManager.play_voice_file("res://assets/audio/lumi_level1.wav",
		"Welcome to the Magical Expression Garden! Show me your brightest smiles and silly faces for the next 60 seconds!", 6.0)

func _init_world_elements() -> void:
	# 1. Distant fairytale trees
	tree_data.clear()
	tree_data.append({"pos": Vector2(140, 470), "scale": 1.2, "type": "willow", "color": Color(0.18, 0.52, 0.32)})
	tree_data.append({"pos": Vector2(320, 485), "scale": 0.9, "type": "oak", "color": Color(0.22, 0.58, 0.36)})
	tree_data.append({"pos": Vector2(980, 475), "scale": 1.1, "type": "oak", "color": Color(0.20, 0.55, 0.34)})
	tree_data.append({"pos": Vector2(1160, 465), "scale": 1.3, "type": "willow", "color": Color(0.16, 0.50, 0.30)})
	
	# 2. Clouds
	cloud_data.clear()
	for i in range(6):
		cloud_data.append({
			"pos": Vector2(i * 240.0 + randf_range(-40, 40), randf_range(70, 180)),
			"speed": randf_range(16.0, 32.0),
			"scale": randf_range(0.9, 1.5)
		})
	
	# 3. Vibrant Blooming Flowers (Foreground and Middleground)
	flower_data.clear()
	for i in range(16):
		flower_data.append({
			"pos": Vector2(50.0 + i * 78.0 + randf_range(-15, 15), 610.0 + randf_range(-20, 30)),
			"hue": float(i) / 16.0,
			"bloom_scale": 1.0,
			"target_bloom": 1.0,
			"sway_offset": randf() * TAU
		})
	
	# 4. Glowing Fairytale Mushrooms
	mushroom_data.clear()
	for i in range(8):
		mushroom_data.append({
			"pos": Vector2(90.0 + i * 160.0 + randf_range(-30, 30), 650.0 + randf_range(-10, 15)),
			"color": Color.from_hsv(randf_range(0.72, 0.95), 0.85, 1.0),
			"scale": randf_range(0.85, 1.25)
		})
	
	# 5. Fluttering Butterflies
	butterfly_data.clear()
	for i in range(6):
		butterfly_data.append({
			"pos": Vector2(randf_range(150, 1130), randf_range(250, 480)),
			"base_pos": Vector2(randf_range(150, 1130), randf_range(250, 480)),
			"hue": randf(),
			"seed": randf() * 10.0,
			"speed": randf_range(1.2, 2.0)
		})

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 60-Second Level Timer Processing
	if not level_finished:
		time_remaining = maxf(0.0, time_remaining - delta)
		hud.set_timer(time_remaining)
		if time_remaining <= 0.0:
			_on_level_timer_complete()
	
	# Handle sleepy mode duration
	if is_sleepy_mode:
		sleepy_timer -= delta
		if sleepy_timer <= 0.0:
			is_sleepy_mode = false
	
	_update_environment_physics(delta)
	
	if garden_canvas:
		garden_canvas.queue_redraw()

func _update_environment_physics(delta: float) -> void:
	# Clouds drift
	for c in cloud_data:
		c["pos"].x += c["speed"] * delta
		if c["pos"].x > 1380.0:
			c["pos"].x = -160.0
			c["pos"].y = randf_range(70, 180)
			
	# Flower blooms interpolate smoothly back to resting scale
	for f in flower_data:
		f["bloom_scale"] = lerpf(f["bloom_scale"], f["target_bloom"], delta * 4.0)
		
	# Butterflies fly in natural flutter patterns
	for b in butterfly_data:
		var s: float = b["seed"]
		var spd: float = b["speed"]
		b["pos"].x = b["base_pos"].x + sin(time_elapsed * spd + s) * 70.0 + cos(time_elapsed * 0.5 + s) * 30.0
		b["pos"].y = b["base_pos"].y + cos(time_elapsed * spd * 1.3 + s) * 40.0 + sin(time_elapsed * 0.8) * 20.0

func _on_face_detected(expr: String, _scores: Dictionary, _eye_closed_sec: float) -> void:
	if level_finished:
		return
	
	var now := Time.get_ticks_msec() / 1000.0
	if (now - last_action_time) < ACTION_COOLDOWN:
		return
	
	match expr:
		"smile":
			_trigger_smile(now)
		"mouth_open":
			_trigger_bubbles(now)
		"eyebrows":
			_trigger_star_burst(now)
		"sleepy":
			_trigger_sleepy_garden(now)
		"surprised", "head_tilt":
			_trigger_wind_gust(now)

# ------------------------------------------------------------------------------
# 5 INDEPENDENT ACTION HANDLERS — WORK REPEATEDLY THROUGHOUT THE 60 SECONDS
# ------------------------------------------------------------------------------
func _trigger_smile(now: float) -> void:
	last_action_time = now
	completed_actions["smile"] = true
	AudioManager.play_sfx("bloom")
	hud.set_instruction("Radiant Smile! Pink tulips blooming along the garden! 🌸")
	
	# Spawn 3 natural blooming tulips across grass ground level
	for i in range(3):
		var rx := randf_range(120.0, 1160.0)
		var ry := randf_range(540.0, 650.0)
		_spawn_blooming_tulip(Vector2(rx, ry))
		
	# Existing flower blooms pulse
	for f in flower_data:
		f["bloom_scale"] = 1.6
		
	if sparkle_particles:
		sparkle_particles.restart()
		sparkle_particles.emitting = true
		
	_update_objective_ui()

func _spawn_blooming_tulip(pos: Vector2) -> void:
	var tulip := Sprite2D.new()
	tulip.texture = tulip_tex
	tulip.centered = true
	tulip.offset = Vector2(0, -60) # Origin at stem base
	tulip.position = pos
	tulip.scale = Vector2(0.06, 0.06) # Starts as tiny bud
	tulip.modulate = Color(1.0, 0.95, 0.98, 0.95)
	
	if tulip_container:
		tulip_container.add_child(tulip)
	else:
		$WorldLayer.add_child(tulip)
		
	var tw := create_tween()
	# 1. Bud appearance & stem upward growth + petal opening into full bloom
	var target_scale := Vector2(randf_range(0.60, 0.78), randf_range(0.60, 0.78))
	tw.tween_property(tulip, "scale", target_scale, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(tulip, "position:y", pos.y - 18.0, 0.65)
	tw.parallel().tween_property(tulip, "rotation", randf_range(-0.08, 0.08), 0.65)
	# 2. Gentle sway and sparkle hold
	tw.tween_property(tulip, "rotation", randf_range(-0.05, 0.05), 1.8)
	# 3. Soft fade out
	tw.tween_property(tulip, "modulate:a", 0.0, 0.75)
	tw.tween_callback(tulip.queue_free)

func _trigger_bubbles(now: float) -> void:
	last_action_time = now
	completed_actions["mouth_open"] = true
	AudioManager.play_sfx("bubble_pop")
	hud.set_instruction("Big Open Mouth! Colorful iridescent bubbles soaring! 🫧")
	
	# Spawn 12 colorful soaring bubbles
	for i in range(12):
		_spawn_bubble(Vector2(640.0 + randf_range(-260, 260), 540.0 + randf_range(-20, 20)))
		
	_update_objective_ui()

func _spawn_bubble(start_pos: Vector2) -> void:
	var bubble := Node2D.new()
	bubble.position = start_pos
	bubble.set_meta("radius", randf_range(18.0, 38.0))
	bubble.set_meta("color", Color.from_hsv(randf(), 0.75, 1.0, 0.85))
	bubble_container.add_child(bubble)
	
	var tw := create_tween()
	var dest := start_pos + Vector2(randf_range(-160, 160), -randf_range(340, 560))
	tw.tween_property(bubble, "position", dest, randf_range(1.6, 2.5))
	tw.parallel().tween_property(bubble, "scale", Vector2(1.5, 1.5), 2.0)
	tw.parallel().tween_property(bubble, "modulate:a", 0.0, 2.3)
	tw.tween_callback(bubble.queue_free)

func _trigger_star_burst(now: float) -> void:
	last_action_time = now
	completed_actions["eyebrows"] = true
	AudioManager.play_sfx("chime")
	hud.set_instruction("Eyebrows Raised! Magical stars shooting across the sky! ⭐")
	
	# Spawn 18 sparkling stars
	for i in range(18):
		_spawn_star(Vector2(randf_range(200, 1080), randf_range(120, 440)))
		
	_update_objective_ui()

func _spawn_star(pos: Vector2) -> void:
	var star := Node2D.new()
	star.position = pos
	star.set_meta("color", Color.from_hsv(randf_range(0.12, 0.18), 0.9, 1.0))
	star.set_meta("scale_val", randf_range(1.4, 2.4))
	star_container.add_child(star)
	
	var tw := create_tween()
	tw.tween_property(star, "scale", Vector2(2.0, 2.0), 0.4)
	tw.parallel().tween_property(star, "rotation", TAU, 0.8)
	tw.tween_property(star, "modulate:a", 0.0, 0.4)
	tw.tween_callback(star.queue_free)

func _trigger_sleepy_garden(now: float) -> void:
	last_action_time = now
	completed_actions["sleepy"] = true
	AudioManager.play_sfx("sleepy")
	hud.set_instruction("Sleepy Eyes! Peaceful twilight washes over the garden! 🌙")
	
	is_sleepy_mode = true
	sleepy_timer = 3.5
	_update_objective_ui()

func _trigger_wind_gust(now: float) -> void:
	last_action_time = now
	completed_actions["surprised"] = true
	AudioManager.play_sfx("wind_gust")
	hud.set_instruction("Surprised Expression! Magical breeze sweeping the garden! 💨")
	
	if wind_particles:
		wind_particles.restart()
		wind_particles.emitting = true
		
	for f in flower_data:
		f["sway_offset"] += PI
		
	_update_objective_ui()

func _update_objective_ui() -> void:
	var done_count := 0
	
	if completed_actions["smile"]:
		done_count += 1
		obj_smile_label.text = "🌸 SMILE: Radiant Bloom! ✔"
		obj_smile_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
	else:
		obj_smile_label.text = "🌸 SMILE: Show bright smile"
		obj_smile_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["mouth_open"]:
		done_count += 1
		obj_mouth_label.text = "🫧 OPEN MOUTH: Bubbles Soared! ✔"
		obj_mouth_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
	else:
		obj_mouth_label.text = "🫧 OPEN MOUTH: Open wide for bubbles"
		obj_mouth_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["eyebrows"]:
		done_count += 1
		obj_eyebrows_label.text = "⭐ RAISE EYEBROWS: Stars Burst! ✔"
		obj_eyebrows_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
	else:
		obj_eyebrows_label.text = "⭐ RAISE EYEBROWS: Lift brows up"
		obj_eyebrows_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["sleepy"]:
		done_count += 1
		obj_sleepy_label.text = "🌙 SLEEPY: Garden Slumbered! ✔"
		obj_sleepy_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
	else:
		obj_sleepy_label.text = "🌙 SLEEPY: Close eyes 1s for twilight"
		obj_sleepy_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["surprised"]:
		done_count += 1
		obj_surprised_label.text = "💨 SURPRISED: Wind Gust Blew! ✔"
		obj_surprised_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
	else:
		obj_surprised_label.text = "💨 SURPRISED: Wide eyes & mouth"
		obj_surprised_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	obj_counter_label.text = "EXPRESSION DISCOVERY (%d / 5)" % done_count

# ------------------------------------------------------------------------------
# EXACT 60-SECOND TIMER COMPLETION
# ------------------------------------------------------------------------------
func _on_level_timer_complete() -> void:
	if level_finished:
		return
	level_finished = true
	
	hud.set_instruction("TIME'S UP! 🌸 Magical Expression Garden Conquered! 🏆")
	AudioManager.play_sfx("combo")
	
	if victory_panel:
		victory_panel.visible = true
		var tw_v := create_tween()
		tw_v.tween_property(victory_panel, "scale", Vector2(1.08, 1.08), 0.25)
		tw_v.tween_property(victory_panel, "scale", Vector2.ONE, 0.25)
		
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		GameManager.complete_level(1)
		get_tree().change_scene_to_file("res://scenes/level_results.tscn")
	)

# ------------------------------------------------------------------------------
# ILLUSTRATED GARDEN ENVIRONMENT DRAWING
# ------------------------------------------------------------------------------
func _draw_garden_canvas() -> void:
	if not garden_canvas:
		return

	# A. Atmospheric Lighting Overlay if Sleepy Mode
	if is_sleepy_mode:
		garden_canvas.draw_rect(Rect2(0, 0, 1280, 720), Color(0.06, 0.08, 0.28, 0.52))
		# Crescent moon in sky
		garden_canvas.draw_circle(Vector2(1100, 130), 38.0, Color(1.0, 0.96, 0.7, 0.9))
		garden_canvas.draw_circle(Vector2(1085, 120), 32.0, Color(0.08, 0.10, 0.32, 0.9))
	else:
		# Soft Golden Sunlight Lens Flare shimmer in upper sky
		var sun_pos := Vector2(220, 110)
		var sun_pulse := sin(time_elapsed * 2.0) * 8.0
		garden_canvas.draw_circle(sun_pos, 55.0 + sun_pulse, Color(1.0, 0.92, 0.5, 0.22))
		garden_canvas.draw_circle(sun_pos, 35.0, Color(1.0, 0.98, 0.7, 0.45))

	# B. Fairytale Sparkle Spores drifting gently
	for i in range(8):
		var spore_x := fmod(i * 170.0 + time_elapsed * 24.0, 1280.0)
		var spore_y := 200.0 + sin(time_elapsed * 1.8 + i) * 60.0
		garden_canvas.draw_circle(Vector2(spore_x, spore_y), 3.0, Color(1.0, 1.0, 0.7, 0.6))

	# E. Glowing Fairytale Mushrooms
	for m in mushroom_data:
		var mp: Vector2 = m["pos"]
		var sc: float = m["scale"]
		var m_col: Color = m["color"]
		if is_sleepy_mode:
			m_col = m_col.lightened(0.35)
			# Soft magical glow around mushroom cap
			garden_canvas.draw_circle(mp, 35.0 * sc, Color(m_col.r, m_col.g, m_col.b, 0.3))
		# Stem
		garden_canvas.draw_line(mp, mp + Vector2(0, 36 * sc), Color(0.92, 0.92, 0.96), 9.0 * sc)
		# Cap
		garden_canvas.draw_arc(mp, 22.0 * sc, PI, TAU, 16, m_col, 18.0 * sc)
		# Spots
		garden_canvas.draw_circle(mp + Vector2(-9 * sc, -8 * sc), 3.2 * sc, Color.WHITE)
		garden_canvas.draw_circle(mp + Vector2(9 * sc, -6 * sc), 2.8 * sc, Color.WHITE)

	# F. Blooming Flowerbed Ambient Sparkles & Glows
	for f in flower_data:
		var fp: Vector2 = f["pos"]
		var b_sc: float = f["bloom_scale"]
		if b_sc > 1.05:
			# Soft magical glow around blossoming areas on the grass
			garden_canvas.draw_circle(fp, 28.0 * b_sc, Color(1.0, 0.55, 0.8, 0.3))
			garden_canvas.draw_circle(fp, 14.0 * b_sc, Color(1.0, 0.92, 0.45, 0.5))

	# G. Fluttering Butterflies
	for b in butterfly_data:
		var bp: Vector2 = b["pos"]
		var wing_flap := absf(sin(time_elapsed * 9.0 + b["seed"])) * 11.0
		var b_col := Color.from_hsv(b["hue"], 0.8, 1.0, 0.92)
		garden_canvas.draw_ellipse(bp - Vector2(9, 0), 12.0, wing_flap, b_col)
		garden_canvas.draw_ellipse(bp + Vector2(9, 0), 12.0, wing_flap, b_col.lightened(0.2))
		garden_canvas.draw_circle(bp, 3.2, Color(0.12, 0.12, 0.2))

	# H. Active Bubbles
	for b in bubble_container.get_children():
		var rad: float = b.get_meta("radius", 22.0)
		var b_col: Color = b.get_meta("color", Color.CYAN)
		var bp: Vector2 = b.position
		garden_canvas.draw_circle(bp, rad, b_col)
		garden_canvas.draw_circle(bp + Vector2(-rad * 0.35, -rad * 0.35), rad * 0.25, Color(1, 1, 1, 0.85))

	# I. Active Shooting Stars
	for s in star_container.get_children():
		var s_col: Color = s.get_meta("color", Color.YELLOW)
		var sp: Vector2 = s.position
		var sc: float = s.get_meta("scale_val", 1.8)
		garden_canvas.draw_polygon(PackedVector2Array([
			sp + Vector2(0, -18 * sc), sp + Vector2(5 * sc, -5 * sc), sp + Vector2(18 * sc, 0),
			sp + Vector2(5 * sc, 5 * sc), sp + Vector2(0, 18 * sc), sp + Vector2(-5 * sc, 5 * sc),
			sp + Vector2(-18 * sc, 0), sp + Vector2(-5 * sc, -5 * sc)
		]), PackedColorArray([s_col]))
		garden_canvas.draw_circle(sp, 4.0 * sc, Color.WHITE)
