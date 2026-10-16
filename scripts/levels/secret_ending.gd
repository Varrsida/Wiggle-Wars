extends Control

## WIGGLE WARS! — Secret Final Surprise 🎁🌈
## Surprise Wonderland — The Hidden Ending
## Cinematic sequence:
## Scene A: Glowing rainbow door opens
## Scene B: Characters appear (Baby Penguin, Shinchan, Lumi, Flowers, Fruits)
## Scene C: Big Wonderland celebration with confetti
## Scene D: Lumi delivers exact fixed final quote with subtitles & angelic voice
## Exact final on-screen message revealed typewriter-style:
## "YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. 🌈"
## Final Reward Screen: "WIGGLE WARS LEGEND! 🏆" with 5-Sticker Memory Scrapbook Album

@onready var background_panel: Panel = $Background
@onready var wonderland_canvas: Node2D = $WonderlandCanvas
@onready var door_node: Node2D = $WonderlandCanvas/RainbowDoor
@onready var confetti_particles: CPUParticles2D = $ConfettiParticles
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/Margin/Label
@onready var final_message_label: Label = $FinalMessageLabel
@onready var reward_screen: PanelContainer = $RewardScreen
@onready var cards_container: HBoxContainer = $RewardScreen/Margin/VBox/Scroll/CardsContainer

enum CinematicState {
	OPENING_SURPRISE,
	SCENE_A_DOOR_OPENS,
	SCENE_B_EVERYONE_APPEARS,
	SCENE_C_CELEBRATION,
	SCENE_D_EMOTIONAL_QUOTE,
	FINAL_MESSAGE_REVEAL,
	REWARD_SCREEN
}

var current_state: CinematicState = CinematicState.OPENING_SURPRISE
var state_timer: float = 0.0
var time_elapsed: float = 0.0

const EXACT_FINAL_QUOTE := "Hey, superstar… the real magic was never the points, the prizes, or the victory. It was YOU — every silly move, every laugh, and every moment you didn't give up. Thank you for making this little world come alive. I'll be right here whenever you return."

const EXACT_FINAL_MESSAGE := "YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. 🌈"

var message_char_index: int = 0
var message_reveal_timer: float = 0.0

var penguin_tex: Texture2D = null
var shinchan_tex: Texture2D = null
var angel_tex: Texture2D = null

# Dreamy Pinterest Aesthetic Data
var fairy_lights: Array[Dictionary] = []
var floating_petals: Array[Dictionary] = []
var interactive_butterflies: Array[Dictionary] = []
var interactive_flowers: Array[Dictionary] = []
var last_hand_pos: Vector2 = Vector2.ZERO

const MEMORIES: Dictionary = {
	1: {
		"title": "Radiant Bloom 🌸",
		"level": "Level 1: Face Frenzy",
		"memory": "Remember that radiant smile that bloomed pink tulips across the sunny grass? Pure sunshine!",
		"icon": "res://assets/sprites/sticker_level1.png",
		"tag": "GARDEN MEMORY"
	},
	2: {
		"title": "Juicy Slicer 🍉",
		"level": "Level 2: Fruit Ninja",
		"memory": "Lightning-fast air slices sent tropical fruits flying and juicy splashes soaring across the lake!",
		"icon": "res://assets/sprites/sticker_level2.png",
		"tag": "LAKE MEMORY"
	},
	3: {
		"title": "Arctic Waddler 🐧",
		"level": "Level 3: Waddle Wars",
		"memory": "Leaning, jumping, and belly-sliding together with our adorable baby penguin in his cozy beanie!",
		"icon": "res://assets/sprites/sticker_level3.png",
		"tag": "ARCTIC MEMORY"
	},
	4: {
		"title": "Stage Star 🎭",
		"level": "Level 4: Copycat Chaos",
		"memory": "Striking the hero pose, waving hello, and dancing wildly with Shinchan on the grand stage!",
		"icon": "res://assets/sprites/sticker_level4.png",
		"tag": "THEATER MEMORY"
	},
	5: {
		"title": "Chaos Champion 🎡",
		"level": "Level 5: Lucky Chaos Wheel",
		"memory": "Braving the giant pink carnival wheel, conquering silly challenges, and claiming party treats!",
		"icon": "res://assets/sprites/sticker_level5.png",
		"tag": "CARNIVAL MEMORY"
	}
}

func _ready() -> void:
	# Verify genuine arrival via agreed routes or full completion
	if not (GameManager.secret_ending_unlocked or GameManager.can_unlock_secret_ending()):
		printerr("[SecretEnding] Violation: Triggered without genuine route completion!")
		GameManager.return_to_main_menu()
		return

	penguin_tex = load("res://assets/characters/penguin_hero.png")
	shinchan_tex = load("res://assets/characters/shinchan_hero.png")
	angel_tex = load("res://assets/characters/angel_lumi.png")

	dialogue_panel.visible = false
	final_message_label.visible = false
	reward_screen.visible = false
	
	_init_pinterest_decorations()
	
	GestureListener.hand_detected.connect(_on_hand_detected)
	GestureListener.face_detected.connect(_on_face_detected)

	if wonderland_canvas:
		wonderland_canvas.draw.connect(_draw_wonderland)
	
	_enter_state(CinematicState.OPENING_SURPRISE)

func _init_pinterest_decorations() -> void:
	# 1. Fairy Light Garlands draped across top
	fairy_lights.clear()
	for i in range(16):
		var x := i * 85.0 + 20.0
		var sag := sin((float(i) / 15.0) * PI) * 55.0 + 35.0
		fairy_lights.append({
			"pos": Vector2(x, sag),
			"color": [
				Color(1.0, 0.95, 0.8), # Warm Gold
				Color(1.0, 0.85, 0.9), # Blush Pink
				Color(0.88, 0.82, 1.0) # Soft Lavender
			][i % 3]
		})

	# 2. Delicate Cherry Blossom Floating Petals
	floating_petals.clear()
	for i in range(24):
		floating_petals.append({
			"pos": Vector2(randf_range(20, 1260), randf_range(0, 720)),
			"speed": randf_range(25.0, 50.0),
			"sway_spd": randf_range(1.5, 3.0),
			"sway_amp": randf_range(15.0, 35.0),
			"phase": randf() * TAU,
			"rot": randf() * TAU,
			"rot_spd": randf_range(-1.2, 1.2),
			"scale": randf_range(0.7, 1.3),
			"color": Color(1.0, randf_range(0.80, 0.92), randf_range(0.85, 0.95), 0.75)
		})

func _process(delta: float) -> void:
	time_elapsed += delta
	state_timer += delta
	
	# Update floating petals
	for p in floating_petals:
		p["pos"].y += p["speed"] * delta
		p["rot"] += p["rot_spd"] * delta
		if p["pos"].y > 740.0:
			p["pos"].y = -20.0
			p["pos"].x = randf_range(20, 1260)

	# Update interactive butterflies
	var surviving_bf: Array[Dictionary] = []
	for bf in interactive_butterflies:
		bf["pos"] += bf["vel"] * delta
		bf["life"] -= delta
		if bf["life"] > 0.0:
			surviving_bf.append(bf)
	interactive_butterflies = surviving_bf

	# Update interactive blooming flowers
	var surviving_fl: Array[Dictionary] = []
	for fl in interactive_flowers:
		fl["scale"] = lerpf(fl["scale"], fl["target_scale"], delta * 3.5)
		fl["life"] -= delta
		if fl["life"] > 0.0:
			surviving_fl.append(fl)
	interactive_flowers = surviving_fl
	
	match current_state:
		CinematicState.OPENING_SURPRISE:
			if state_timer >= 4.0:
				_enter_state(CinematicState.SCENE_A_DOOR_OPENS)
		CinematicState.SCENE_A_DOOR_OPENS:
			if state_timer >= 3.5:
				_enter_state(CinematicState.SCENE_B_EVERYONE_APPEARS)
		CinematicState.SCENE_B_EVERYONE_APPEARS:
			if state_timer >= 3.5:
				_enter_state(CinematicState.SCENE_C_CELEBRATION)
		CinematicState.SCENE_C_CELEBRATION:
			if state_timer >= 4.0:
				_enter_state(CinematicState.SCENE_D_EMOTIONAL_QUOTE)
		CinematicState.SCENE_D_EMOTIONAL_QUOTE:
			# Authoritative duration ensuring Lumi finishes full 247-character quote
			if state_timer >= 18.0:
				_enter_state(CinematicState.FINAL_MESSAGE_REVEAL)
		CinematicState.FINAL_MESSAGE_REVEAL:
			message_reveal_timer += delta
			if message_reveal_timer >= 0.06 and message_char_index < EXACT_FINAL_MESSAGE.length():
				message_reveal_timer = 0.0
				message_char_index += 1
				final_message_label.text = EXACT_FINAL_MESSAGE.substr(0, message_char_index)
			elif message_char_index >= EXACT_FINAL_MESSAGE.length() and state_timer >= 6.5:
				_enter_state(CinematicState.REWARD_SCREEN)
				
	if wonderland_canvas:
		wonderland_canvas.queue_redraw()

func _enter_state(new_state: CinematicState) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		CinematicState.OPENING_SURPRISE:
			dialogue_panel.visible = true
			dialogue_label.text = "Lumi: \"Psst… wait! There's one more little surprise for you!\""
			AudioManager.play_voice_file("res://assets/audio/lumi_surprise_open.wav",
				"Psst… wait! There's one more little surprise for you!", 4.0)
			AudioManager.play_sfx("chime")

		CinematicState.SCENE_A_DOOR_OPENS:
			dialogue_panel.visible = false
			AudioManager.play_sfx("legend_fanfare")

		CinematicState.SCENE_B_EVERYONE_APPEARS:
			AudioManager.play_sfx("chirp")
			AudioManager.play_sfx("boing")

		CinematicState.SCENE_C_CELEBRATION:
			confetti_particles.emitting = true
			AudioManager.play_sfx("wheel_win")

		CinematicState.SCENE_D_EMOTIONAL_QUOTE:
			dialogue_panel.visible = true
			dialogue_label.text = "Lumi: \"" + EXACT_FINAL_QUOTE + "\""
			AudioManager.play_voice_file("res://assets/audio/lumi_final_quote.wav",
				EXACT_FINAL_QUOTE, 16.0)

		CinematicState.FINAL_MESSAGE_REVEAL:
			dialogue_panel.visible = false
			final_message_label.visible = true
			final_message_label.text = ""
			message_char_index = 0
			message_reveal_timer = 0.0
			AudioManager.play_sfx("chime")

		CinematicState.REWARD_SCREEN:
			final_message_label.visible = false
			reward_screen.visible = true
			_populate_scrapbook_cards()
			AudioManager.play_sfx("legend_fanfare")

func _populate_scrapbook_cards() -> void:
	if not cards_container:
		return
	for c in cards_container.get_children():
		c.queue_free()
		
	for i in range(1, 6):
		var mem: Dictionary = MEMORIES[i]
		var unlocked: bool = true
		if StickerManager:
			unlocked = StickerManager.is_sticker_unlocked(i)
		var st_data: Dictionary = {}
		if StickerManager:
			st_data = StickerManager.get_sticker_data(i)
			
		var card_panel := PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(210, 340)
		
		var sb := StyleBoxFlat.new()
		if unlocked:
			sb.bg_color = Color(1.0, 0.98, 0.95, 0.96)
			sb.border_color = Color(0.92, 0.65, 0.78, 1.0)
			sb.set_border_width_all(3)
			sb.shadow_color = Color(0.85, 0.65, 0.75, 0.35)
			sb.shadow_size = 8
		else:
			sb.bg_color = Color(0.92, 0.90, 0.94, 0.85)
			sb.border_color = Color(0.75, 0.72, 0.80, 0.8)
			sb.set_border_width_all(2)
			sb.shadow_color = Color(0.6, 0.6, 0.65, 0.15)
			sb.shadow_size = 4
		sb.set_corner_radius_all(16)
		card_panel.add_theme_stylebox_override("panel", sb)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		card_panel.add_child(margin)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)
		
		var tag_lbl := Label.new()
		tag_lbl.text = mem["tag"]
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.65) if unlocked else Color(0.55, 0.55, 0.60))
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(tag_lbl)
		
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(100, 100)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = st_data.get("icon", mem["icon"])
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		icon_rect.modulate = Color.WHITE if unlocked else Color(0.4, 0.4, 0.45, 0.6)
		vbox.add_child(icon_rect)
		
		var title_lbl := Label.new()
		title_lbl.text = mem["title"] if unlocked else "🔒 LOCKED"
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.add_theme_color_override("font_color", Color(0.25, 0.15, 0.22) if unlocked else Color(0.5, 0.5, 0.55))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = mem["memory"] if unlocked else "Complete %s to unlock this memory!" % mem["level"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.4, 0.35, 0.42) if unlocked else Color(0.6, 0.6, 0.65))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc_lbl)
		
		cards_container.add_child(card_panel)

func _on_scrapbook_pressed() -> void:
	AudioManager.play_sfx("chime")
	get_tree().change_scene_to_file("res://scenes/scrapbook.tscn")

func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.reset_game_state()
	GameManager.start_game()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.return_to_main_menu()

# ------------------------------------------------------------------------------
# INTERACTIVE GESTURE HANDLERS (HAND MOTION -> BUTTERFLIES, SMILE -> FLOWERS)
# ------------------------------------------------------------------------------
func _on_hand_detected(cursor_pos: Vector2, _swipe: String, _waving: bool, _wave_spd: float, _reach: bool, _open: bool, _fist: bool) -> void:
	var screen_pos := Vector2(cursor_pos.x * 1280.0, cursor_pos.y * 720.0)
	if last_hand_pos.distance_to(screen_pos) > 35.0:
		last_hand_pos = screen_pos
		_spawn_butterfly(screen_pos)

func _spawn_butterfly(pos: Vector2) -> void:
	if interactive_butterflies.size() < 16:
		interactive_butterflies.append({
			"pos": pos,
			"vel": Vector2(randf_range(-35, 35), randf_range(-90, -45)),
			"color": Color.from_hsv(randf_range(0.78, 0.96), 0.65, 1.0, 0.88),
			"life": 2.2,
			"seed": randf() * 10.0
		})

func _on_face_detected(expr: String, _scores: Dictionary, _eye_sec: float) -> void:
	if expr == "smile":
		_spawn_wonderland_flower(Vector2(randf_range(160, 1120), randf_range(520, 650)))

func _spawn_wonderland_flower(pos: Vector2) -> void:
	if interactive_flowers.size() < 12:
		interactive_flowers.append({
			"pos": pos,
			"scale": 0.1,
			"target_scale": randf_range(0.85, 1.35),
			"color": Color.from_hsv(randf_range(0.82, 0.98), 0.55, 1.0, 0.92),
			"life": 3.0
		})

# ------------------------------------------------------------------------------
# DREAMY PINTEREST-INSPIRED SURPRISE WONDERLAND DRAWING
# ------------------------------------------------------------------------------
func _draw_wonderland() -> void:
	if not wonderland_canvas:
		return
		
	# A. Soft Dreamy Pastel Fairy Light Garlands across Top
	for i in range(fairy_lights.size() - 1):
		var p1: Vector2 = fairy_lights[i]["pos"]
		var p2: Vector2 = fairy_lights[i+1]["pos"]
		wonderland_canvas.draw_line(p1, p2, Color(0.88, 0.78, 0.6, 0.65), 1.8)
	for fl in fairy_lights:
		var fp: Vector2 = fl["pos"]
		var f_col: Color = fl["color"]
		var pulse := sin(time_elapsed * 3.0 + fp.x * 0.05) * 3.0
		# Soft glowing halo
		wonderland_canvas.draw_circle(fp, 16.0 + pulse, Color(f_col.r, f_col.g, f_col.b, 0.28))
		# Inner bright bulb
		wonderland_canvas.draw_circle(fp, 6.0, Color(1.0, 1.0, 0.9, 0.95))

	# B. Floating Cherry Blossom Petals
	for pt in floating_petals:
		var pp: Vector2 = pt["pos"]
		var p_sway: float = sin(time_elapsed * float(pt["sway_spd"]) + float(pt["phase"])) * float(pt["sway_amp"])
		var p_draw_pos := Vector2(pp.x + p_sway, pp.y)
		var sc: float = pt["scale"]
		var p_col: Color = pt["color"]
		wonderland_canvas.draw_ellipse(p_draw_pos, 7.0 * sc, 4.0 * sc, p_col)

	# C. Upgraded Magical Atmospheric Rainbow Archway & Storybook Portal
	var center := Vector2(640.0, 420.0)
	var door_glow: float = absf(sin(time_elapsed * 2.5)) * 0.25 + 0.75
	
	# Atmospheric starlight glow behind the rainbow matching the night sky
	wonderland_canvas.draw_arc(center, 230.0, PI, TAU, 48, Color(0.9, 0.8, 1.0, 0.15 * door_glow), 120.0)
	
	var magical_rainbow := [
		Color(1.0, 0.45, 0.65), # Rose Pink
		Color(1.0, 0.70, 0.45), # Peach Coral
		Color(1.0, 0.95, 0.55), # Warm Buttercream
		Color(0.55, 0.95, 0.75), # Mint Green
		Color(0.45, 0.85, 1.00), # Sky Blue
		Color(0.65, 0.55, 1.00), # Indigo Lavender
		Color(0.85, 0.55, 0.95)  # Violet
	]
	for i in range(magical_rainbow.size()):
		var r := 175.0 + i * 16.0
		var c: Color = magical_rainbow[i] * door_glow
		c.a = 0.85
		wonderland_canvas.draw_arc(center, r, PI, TAU, 54, c, 13.0)
		
	# Sparkles dancing along the rainbow arch
	for i in range(12):
		var spk_a := PI + (float(i) / 11.0) * PI
		var spk_r := 175.0 + fmod(time_elapsed * 20.0 + i * 22.0, 96.0)
		var spk_pos := center + Vector2(cos(spk_a), sin(spk_a)) * spk_r
		var spk_alpha := absf(sin(time_elapsed * 4.0 + i)) * 0.85
		wonderland_canvas.draw_circle(spk_pos, 2.5, Color(1.0, 1.0, 0.85, spk_alpha))

	# Storybook Magical Portal Entrance (Replacing plain rectangular door)
	# 1. Swirling Starlight Vortex inside portal arch
	wonderland_canvas.draw_arc(center + Vector2(0, -10), 85.0, PI, TAU, 32, Color(0.12, 0.08, 0.28, 0.92), 170.0)
	for s in range(8):
		var v_rad := 20.0 + s * 8.5
		var v_rot := time_elapsed * (1.5 - s * 0.1)
		var v_col := Color.from_hsv(fmod(float(s)/8.0 + time_elapsed * 0.1, 1.0), 0.65, 1.0, 0.45 * door_glow)
		wonderland_canvas.draw_arc(center + Vector2(0, -40), v_rad, v_rot, v_rot + PI * 1.4, 20, v_col, 3.5)

	# 2. Ornate Storybook Arch Pillars and Moldings
	# Left pillar
	wonderland_canvas.draw_rect(Rect2(center.x - 96, center.y - 70, 18, 120), Color(0.95, 0.85, 0.45, 0.95))
	wonderland_canvas.draw_rect(Rect2(center.x - 92, center.y - 66, 10, 112), Color(1.0, 0.96, 0.75, 0.95))
	# Right pillar
	wonderland_canvas.draw_rect(Rect2(center.x + 78, center.y - 70, 18, 120), Color(0.95, 0.85, 0.45, 0.95))
	wonderland_canvas.draw_rect(Rect2(center.x + 82, center.y - 66, 10, 112), Color(1.0, 0.96, 0.75, 0.95))
	# Storybook Archway Header
	wonderland_canvas.draw_arc(center + Vector2(0, -70), 88.0, PI, TAU, 36, Color(0.95, 0.85, 0.45, 0.95), 14.0)
	wonderland_canvas.draw_arc(center + Vector2(0, -70), 88.0, PI, TAU, 36, Color(1.0, 0.98, 0.82, 0.95), 6.0)
	# Golden star rune keystone at apex
	wonderland_canvas.draw_circle(center + Vector2(0, -160), 12.0, Color(1.0, 0.92, 0.45))
	wonderland_canvas.draw_circle(center + Vector2(0, -160), 7.0, Color.WHITE)

	# D. Characters Gathered Together in Surprise Wonderland
	if current_state >= CinematicState.SCENE_B_EVERYONE_APPEARS:
		# 1. Cute Baby Penguin with Winter Beanie (Left)
		var p_pos := Vector2(300.0 + sin(time_elapsed * 4.0) * 10.0, 500.0)
		wonderland_canvas.draw_ellipse(Vector2(p_pos.x, 575.0), 45.0, 14.0, Color(0.3, 0.2, 0.35, 0.28))
		if penguin_tex:
			var p_w := 140.0
			var p_h := 140.0 * (float(penguin_tex.get_height()) / float(penguin_tex.get_width()))
			wonderland_canvas.draw_texture_rect(penguin_tex, Rect2(p_pos.x - p_w * 0.5, p_pos.y - p_h * 0.5, p_w, p_h), false)

		# 2. Shinchan Standing Hero (Right)
		var c_pos := Vector2(980.0 + sin(time_elapsed * 5.0) * -10.0, 485.0)
		wonderland_canvas.draw_ellipse(Vector2(c_pos.x, 575.0), 45.0, 14.0, Color(0.3, 0.2, 0.35, 0.28))
		if shinchan_tex:
			var s_w := 130.0
			var s_h := 130.0 * (float(shinchan_tex.get_height()) / float(shinchan_tex.get_width()))
			wonderland_canvas.draw_texture_rect(shinchan_tex, Rect2(c_pos.x - s_w * 0.5, c_pos.y - s_h * 0.5, s_w, s_h), false)

		# 3. Supplied Angel Character (Floating Center Above Cloud Horizon)
		if angel_tex:
			var angel_pos := Vector2(640.0, 310.0 + sin(time_elapsed * 2.8) * 14.0)
			# Soft celestial golden halo aura
			wonderland_canvas.draw_circle(angel_pos + Vector2(0, -40), 90.0, Color(1.0, 0.95, 0.75, 0.25 * door_glow))
			wonderland_canvas.draw_circle(angel_pos + Vector2(0, -40), 60.0, Color(1.0, 0.85, 0.95, 0.20 * door_glow))
			var a_w := 240.0
			var a_h := a_w * (float(angel_tex.get_height()) / float(angel_tex.get_width()))
			wonderland_canvas.draw_texture_rect(angel_tex, Rect2(angel_pos.x - a_w * 0.5, angel_pos.y - a_h * 0.5, a_w, a_h), false)

		# 4. Magical Guide Fairy Lumi (Hovering on Upper Left with Wand)
		var lumi_pos := Vector2(460.0, 240.0 + sin(time_elapsed * 3.5) * 14.0)
		var aura_glow := Color(1.0, 0.95, 0.7, 0.40 + sin(time_elapsed * 6.0) * 0.15)
		wonderland_canvas.draw_circle(lumi_pos, 36.0, aura_glow)
		wonderland_canvas.draw_circle(lumi_pos, 24.0, Color(1.0, 1.0, 0.85, 0.6))
		var wing_f := sin(time_elapsed * 12.0) * 6.0
		wonderland_canvas.draw_ellipse(lumi_pos + Vector2(-18, -8), 14.0, 22.0 + wing_f, Color(0.85, 0.95, 1.0, 0.75))
		wonderland_canvas.draw_ellipse(lumi_pos + Vector2(18, -8), 14.0, 22.0 + wing_f, Color(0.85, 0.95, 1.0, 0.75))
		wonderland_canvas.draw_ellipse(lumi_pos + Vector2(0, 10), 11.0, 16.0, Color(0.55, 0.88, 0.98))
		wonderland_canvas.draw_circle(lumi_pos + Vector2(0, -9), 12.0, Color(1.0, 0.90, 0.82))
		wonderland_canvas.draw_circle(lumi_pos + Vector2(-4, -11), 2.0, Color(0.2, 0.4, 0.7))
		wonderland_canvas.draw_circle(lumi_pos + Vector2(4, -11), 2.0, Color(0.2, 0.4, 0.7))
		wonderland_canvas.draw_line(lumi_pos + Vector2(10, 6), lumi_pos + Vector2(26, -6), Color.GOLD, 2.5)
		wonderland_canvas.draw_circle(lumi_pos + Vector2(26, -6), 4.5, Color.WHITE)

	# E. Interactive Blooming Flowers (Spawned by Smiling)
	for fl in interactive_flowers:
		var fp: Vector2 = fl["pos"]
		var fsc: float = fl["scale"]
		var fcol: Color = fl["color"]
		var alpha: float = clampf(fl["life"] / 3.0, 0.0, 1.0)
		for p in range(5):
			var a := p * (TAU / 5.0)
			var petal_p := fp + Vector2(cos(a), sin(a)) * (16.0 * fsc)
			wonderland_canvas.draw_circle(petal_p, 10.0 * fsc, Color(fcol.r, fcol.g, fcol.b, alpha * 0.8))
		wonderland_canvas.draw_circle(fp, 8.0 * fsc, Color(1.0, 0.95, 0.4, alpha))

	# F. Interactive Angel Starlight Feathers & Sparkles (Spawned by Hand Motion)
	for bf in interactive_butterflies:
		var bp: Vector2 = bf["pos"]
		var bcol: Color = bf["color"]
		var balp: float = clampf(bf["life"] / 2.2, 0.0, 1.0)
		# Draw glowing angelic starlight spark
		wonderland_canvas.draw_circle(bp, 6.0, Color(1.0, 0.95, 0.7, balp * 0.9))
		wonderland_canvas.draw_circle(bp, 3.0, Color(1.0, 1.0, 1.0, balp))
		for spk in range(4):
			var sa := spk * (TAU / 4.0) + time_elapsed * 3.0
			var st_tip := bp + Vector2(cos(sa), sin(sa)) * 14.0
			wonderland_canvas.draw_line(bp, st_tip, Color(bcol.r, bcol.g, bcol.b, balp * 0.7), 1.8)
