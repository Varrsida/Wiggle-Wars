extends Node2D

## WIGGLE WARS! — Level 1: Face Frenzy 🌸
## Magical Expression Garden
## Reacts to Smile, Open Mouth, Eyebrow Raise, Eye Closure (Sleepy), and Surprised expression.
## Features visible objective tracker, floating clouds, glowing mushrooms, blooming flowers,
## butterflies, bubbles, stars, wind particles, and grand victory sequence!

@onready var hud: CanvasLayer = $HUD
@onready var garden_canvas: Node2D = $GardenCanvas
@onready var bubble_container: Node2D = $BubbleContainer
@onready var star_container: Node2D = $StarContainer
@onready var wind_particles: CPUParticles2D = $WindParticles
@onready var sparkle_particles: CPUParticles2D = $SparkleParticles
@onready var objective_panel: PanelContainer = $LevelUI/ObjectivePanel
@onready var victory_panel: PanelContainer = $LevelUI/VictoryPanel

# Objective Labels
@onready var obj_smile_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/SmileObj
@onready var obj_mouth_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/MouthObj
@onready var obj_eyebrows_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/EyebrowsObj
@onready var obj_sleepy_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/SleepyObj
@onready var obj_surprised_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/SurprisedObj
@onready var obj_counter_label: Label = $LevelUI/ObjectivePanel/Margin/VBox/Header

var completed_actions: Dictionary = {
	"smile": false,
	"mouth_open": false,
	"eyebrows": false,
	"sleepy": false,
	"surprised": false
}

var last_action_time: float = 0.0
const ACTION_COOLDOWN: float = 0.75
var is_sleepy_mode: bool = false
var level_finished: bool = false

# Procedural animated elements
var flower_nodes: Array[Node2D] = []
var butterfly_nodes: Array[Node2D] = []
var cloud_nodes: Array[Node2D] = []
var mushroom_nodes: Array[Node2D] = []
var time_elapsed: float = 0.0

func _ready() -> void:
	hud.setup_hud("Level 1: Face Frenzy 🌸", "Make silly facial expressions to bring the garden alive!")
	GestureListener.face_detected.connect(_on_face_detected)
	
	if victory_panel:
		victory_panel.visible = false
		
	_update_objective_ui()
	
	AudioManager.play_music_procedural("garden")
	AudioManager.play_voice_file("res://assets/audio/lumi_level1.wav",
		"Welcome to the Magical Expression Garden! Show me your brightest smiles and silly faces!", 6.0)

	_spawn_initial_garden()

func _spawn_initial_garden() -> void:
	# 1. Floating Clouds
	for i in range(5):
		var cloud := Node2D.new()
		cloud.position = Vector2(i * 260.0 + randf_range(20, 80), randf_range(80, 220))
		cloud.set_meta("speed", randf_range(15.0, 30.0))
		cloud.set_meta("scale", randf_range(0.8, 1.4))
		garden_canvas.add_child(cloud)
		cloud_nodes.append(cloud)

	# 2. Glowing Mushrooms
	for i in range(6):
		var mush := Node2D.new()
		mush.position = Vector2(120.0 + i * 200.0 + randf_range(-40, 40), 650.0)
		mush.set_meta("color", Color.from_hsv(randf_range(0.7, 0.95), 0.8, 1.0))
		garden_canvas.add_child(mush)
		mushroom_nodes.append(mush)

	# 3. Colorful Blooming Flowers
	for i in range(14):
		var flower := Node2D.new()
		flower.position = Vector2(60.0 + i * 85.0, 615.0 + randf_range(-25.0, 25.0))
		flower.set_meta("base_scale", 1.0)
		flower.set_meta("bloom_scale", 1.0)
		flower.set_meta("color", Color.from_hsv(float(i) / 14.0, 0.75, 0.95))
		garden_canvas.add_child(flower)
		flower_nodes.append(flower)

	# 4. Butterflies
	for i in range(5):
		var bf := Node2D.new()
		bf.position = Vector2(randf_range(120, 1140), randf_range(220, 480))
		bf.set_meta("seed", randf() * 10.0)
		garden_canvas.add_child(bf)
		butterfly_nodes.append(bf)

func _process(delta: float) -> void:
	time_elapsed += delta
	_animate_garden(delta)
	queue_redraw()

func _animate_garden(delta: float) -> void:
	# Clouds drift slowly
	for c in cloud_nodes:
		var spd: float = c.get_meta("speed", 20.0)
		c.position.x += spd * delta
		if c.position.x > 1350.0:
			c.position.x = -150.0
			c.position.y = randf_range(80, 220)

	# Gentle swaying and breathing of flowers
	for i in range(flower_nodes.size()):
		var f := flower_nodes[i]
		var bloom: float = f.get_meta("bloom_scale", 1.0)
		var sway := sin(time_elapsed * 2.2 + i * 0.45) * 0.08
		f.rotation = sway
		f.scale = Vector2.ONE * (bloom + sin(time_elapsed * 3.0 + i) * 0.04)

	# Butterflies fluttering gracefully
	for b in butterfly_nodes:
		var s: float = b.get_meta("seed", 0.0)
		b.position.x += cos(time_elapsed * 1.6 + s) * 1.5
		b.position.y += sin(time_elapsed * 2.4 + s) * 1.1

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
		"surprised":
			_trigger_wind_gust(now)

func _trigger_smile(now: float) -> void:
	last_action_time = now
	var _first_time: bool = not completed_actions.get("smile", false)
	completed_actions["smile"] = true
	GameManager.add_score(10)
	AudioManager.play_sfx("bloom")
	hud.set_instruction("Radiant Smile! Flowers blooming & glowing! (+10)")
	
	# Flower bloom surge
	for f in flower_nodes:
		var tw := create_tween()
		tw.tween_property(f, "scale", Vector2(1.65, 1.65), 0.25)
		tw.tween_property(f, "scale", Vector2(1.0, 1.0), 0.45)

	_update_objective_ui()
	_check_level_completion()

func _trigger_bubbles(now: float) -> void:
	last_action_time = now
	completed_actions["mouth_open"] = true
	GameManager.add_score(10)
	AudioManager.play_sfx("bubble_pop")
	hud.set_instruction("Big Open Mouth! Colorful bubbles floating! (+10)")
	
	for i in range(10):
		_spawn_bubble(Vector2(640.0 + randf_range(-220, 220), 520.0))

	_update_objective_ui()
	_check_level_completion()

func _spawn_bubble(start_pos: Vector2) -> void:
	var bubble := Node2D.new()
	bubble.position = start_pos
	bubble.set_meta("radius", randf_range(16.0, 32.0))
	bubble.set_meta("color", Color.from_hsv(randf(), 0.7, 0.95, 0.8))
	bubble_container.add_child(bubble)
	
	var tw := create_tween()
	var dest := start_pos + Vector2(randf_range(-140, 140), -randf_range(300, 520))
	tw.tween_property(bubble, "position", dest, randf_range(1.4, 2.2))
	tw.parallel().tween_property(bubble, "scale", Vector2(1.4, 1.4), 1.8)
	tw.parallel().tween_property(bubble, "modulate:a", 0.0, 2.0)
	tw.tween_callback(bubble.queue_free)

func _trigger_star_burst(now: float) -> void:
	last_action_time = now
	completed_actions["eyebrows"] = true
	GameManager.add_score(10)
	AudioManager.play_sfx("chime")
	hud.set_instruction("Eyebrows Raised! Magical stars bursting! (+10)")
	
	for i in range(16):
		_spawn_star(Vector2(randf_range(280, 1000), randf_range(140, 420)))

	_update_objective_ui()
	_check_level_completion()

func _spawn_star(pos: Vector2) -> void:
	var star := Node2D.new()
	star.position = pos
	star.set_meta("color", Color.from_hsv(randf_range(0.12, 0.18), 0.9, 1.0))
	star_container.add_child(star)
	
	var tw := create_tween()
	tw.tween_property(star, "scale", Vector2(1.8, 1.8), 0.35)
	tw.parallel().tween_property(star, "rotation", TAU, 0.7)
	tw.tween_property(star, "modulate:a", 0.0, 0.35)
	tw.tween_callback(star.queue_free)

func _trigger_sleepy_garden(now: float) -> void:
	last_action_time = now
	completed_actions["sleepy"] = true
	GameManager.add_score(15)
	AudioManager.play_sfx("sleepy")
	hud.set_instruction("Peaceful Sleepy Garden! Shhh... glowing nightlights! (+15)")
	
	is_sleepy_mode = true
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_callback(func(): is_sleepy_mode = false)

	_update_objective_ui()
	_check_level_completion()

func _trigger_wind_gust(now: float) -> void:
	last_action_time = now
	completed_actions["surprised"] = true
	GameManager.add_score(15)
	AudioManager.play_sfx("wind_gust")
	hud.set_instruction("Surprised Face! Magical wind gust blowing! (+15)")
	
	if wind_particles:
		wind_particles.emitting = true
	
	for f in flower_nodes:
		var tw := create_tween()
		tw.tween_property(f, "rotation", 0.45, 0.25)
		tw.tween_property(f, "rotation", 0.0, 0.55)

	_update_objective_ui()
	_check_level_completion()

func _update_objective_ui() -> void:
	var done_count := 0
	
	if completed_actions["smile"]:
		done_count += 1
		obj_smile_label.text = "🌸 SMILE: Bloomed! ✔"
		obj_smile_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		obj_smile_label.text = "🌸 SMILE: Show your biggest grin (+10)"
		obj_smile_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["mouth_open"]:
		done_count += 1
		obj_mouth_label.text = "🫧 OPEN MOUTH: Bubbles Soared! ✔"
		obj_mouth_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		obj_mouth_label.text = "🫧 OPEN MOUTH: Open wide for bubbles (+10)"
		obj_mouth_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["eyebrows"]:
		done_count += 1
		obj_eyebrows_label.text = "⭐ RAISE EYEBROWS: Stars Burst! ✔"
		obj_eyebrows_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		obj_eyebrows_label.text = "⭐ RAISE EYEBROWS: Lift brows up (+10)"
		obj_eyebrows_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["sleepy"]:
		done_count += 1
		obj_sleepy_label.text = "🌙 SLEEPY: Garden Slumbered! ✔"
		obj_sleepy_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		obj_sleepy_label.text = "🌙 SLEEPY: Hold eyes closed 1s (+15)"
		obj_sleepy_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if completed_actions["surprised"]:
		done_count += 1
		obj_surprised_label.text = "💨 SURPRISED: Wind Gust Blew! ✔"
		obj_surprised_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		obj_surprised_label.text = "💨 SURPRISED: Wide eyes & mouth (+15)"
		obj_surprised_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	obj_counter_label.text = "EXPRESSION OBJECTIVES (%d / 5)" % done_count

func _check_level_completion() -> void:
	var done_count := 0
	for k in completed_actions:
		if completed_actions[k]:
			done_count += 1
	
	if (done_count >= 5 or GameManager.level_scores.get(1, 0) >= 55) and not level_finished:
		level_finished = true
		hud.set_instruction("GARDEN FULLY BLOOMED! SUPERSTAR!")
		AudioManager.play_sfx("combo")
		
		if victory_panel:
			victory_panel.visible = true
			var tw_v := create_tween()
			tw_v.tween_property(victory_panel, "scale", Vector2(1.1, 1.1), 0.3)
			tw_v.tween_property(victory_panel, "scale", Vector2.ONE, 0.3)
		
		var tw := create_tween()
		tw.tween_interval(2.2)
		tw.tween_callback(func():
			GameManager.complete_level(1)
			get_tree().change_scene_to_file("res://scenes/level_results.tscn")
		)

func _draw() -> void:
	# 1. Clouds
	for c in cloud_nodes:
		var sc: float = c.get_meta("scale", 1.0)
		var cp := c.position
		draw_circle(cp, 32.0 * sc, Color(1, 1, 1, 0.85))
		draw_circle(cp + Vector2(25, -10) * sc, 26.0 * sc, Color(1, 1, 1, 0.85))
		draw_circle(cp + Vector2(-25, -6) * sc, 24.0 * sc, Color(1, 1, 1, 0.85))
		draw_circle(cp + Vector2(48, 8) * sc, 20.0 * sc, Color(1, 1, 1, 0.85))
		draw_circle(cp + Vector2(-44, 10) * sc, 18.0 * sc, Color(1, 1, 1, 0.85))

	# 2. Glowing Mushrooms
	for m in mushroom_nodes:
		var mp := m.position
		var m_col: Color = m.get_meta("color", Color.MAGENTA)
		if is_sleepy_mode:
			m_col = m_col.lightened(0.4)
		# Stem
		draw_line(mp, mp + Vector2(0, 35), Color(0.9, 0.9, 0.95), 8.0)
		# Cap
		draw_arc(mp, 20.0, PI, TAU, 16, m_col, 16.0)
		# Spots
		draw_circle(mp + Vector2(-8, -8), 3.0, Color.WHITE)
		draw_circle(mp + Vector2(8, -6), 2.5, Color.WHITE)

	# 3. Procedural Blooming Flowers
	for f in flower_nodes:
		var col: Color = f.get_meta("color", Color.CORAL)
		if is_sleepy_mode:
			col = col.lerp(Color(0.25, 0.4, 0.75), 0.65)
		# Stem
		draw_line(f.position, f.position + Vector2(0, 55), Color(0.18, 0.65, 0.28), 6.0)
		# Leaf
		draw_ellipse(f.position + Vector2(12, 28), 10.0, 5.0, Color(0.22, 0.72, 0.32))
		# Petals (Layered)
		for p in range(6):
			var angle := p * (TAU / 6.0) + f.rotation
			var p_pos := f.position + Vector2(cos(angle), sin(angle)) * (18.0 * f.scale.x)
			draw_circle(p_pos, 12.0 * f.scale.x, col)
		# Flower center glow
		draw_circle(f.position, 10.0 * f.scale.x, Color(1.0, 0.92, 0.25))
		draw_circle(f.position, 5.0 * f.scale.x, Color(1.0, 1.0, 0.8))

	# 4. Butterflies
	for b in butterfly_nodes:
		var wing_flap: float = absf(sin(time_elapsed * 8.5)) * 9.0
		draw_ellipse(b.position - Vector2(8, 0), 11.0, wing_flap, Color(0.95, 0.35, 0.9, 0.9))
		draw_ellipse(b.position + Vector2(8, 0), 11.0, wing_flap, Color(0.3, 0.8, 1.0, 0.9))
		draw_circle(b.position, 3.0, Color(0.15, 0.15, 0.2))

	# 5. Bubbles
	for b in bubble_container.get_children():
		var rad: float = b.get_meta("radius", 20.0)
		var b_col: Color = b.get_meta("color", Color.CYAN)
		var bp: Vector2 = b.position
		draw_circle(bp, rad, b_col)
		# Bubble shine highlight
		draw_circle(bp + Vector2(-rad*0.35, -rad*0.35), rad*0.25, Color(1, 1, 1, 0.9))

	# 6. Stars
	for s in star_container.get_children():
		var s_col: Color = s.get_meta("color", Color.YELLOW)
		var sp: Vector2 = s.position
		# 4-point star
		draw_polygon(PackedVector2Array([
			sp + Vector2(0, -18), sp + Vector2(5, -5), sp + Vector2(18, 0),
			sp + Vector2(5, 5), sp + Vector2(0, 18), sp + Vector2(-5, 5),
			sp + Vector2(-18, 0), sp + Vector2(-5, -5)
		]), PackedColorArray([s_col]))
		draw_circle(sp, 4.0, Color.WHITE)
