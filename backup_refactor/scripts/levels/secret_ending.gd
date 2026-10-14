extends Control

## WIGGLE WARS! â€” Secret Final Surprise ðŸŽðŸŒˆ
## Surprise Wonderland â€” The Hidden Ending
## Cinematic sequence:
## Scene A: Glowing rainbow door opens
## Scene B: Characters appear (Baby Penguin, Shinchan, Lumi, Flowers, Fruits)
## Scene C: Big Wonderland celebration with confetti
## Scene D: Lumi delivers exact fixed final quote with subtitles & angelic voice
## Exact final on-screen message revealed typewriter-style:
## "YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. ðŸŒˆ"
## Final Reward Screen: "WIGGLE WARS LEGEND! ðŸ†" (Zero score dependencies!)

@onready var background_panel: Panel = $Background
@onready var wonderland_canvas: Node2D = $WonderlandCanvas
@onready var door_node: Node2D = $WonderlandCanvas/RainbowDoor
@onready var confetti_particles: CPUParticles2D = $ConfettiParticles
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/Margin/Label
@onready var final_message_label: Label = $FinalMessageLabel
@onready var reward_screen: PanelContainer = $RewardScreen
@onready var skip_btn: Button = $TopControls/SkipBtn

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

# Dreamy Pinterest Aesthetic Data
var fairy_lights: Array[Dictionary] = []
var floating_petals: Array[Dictionary] = []
var interactive_butterflies: Array[Dictionary] = []
var interactive_flowers: Array[Dictionary] = []
var last_hand_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# STRICT SAFEGUARD: Verify all 5 levels completed and Level 5 results acknowledged!
	if not GameManager.can_unlock_secret_ending():
		printerr("[SecretEnding] Violation: Triggered without genuine completion of all 5 levels!")
		GameManager.return_to_main_menu()
		return

	penguin_tex = load("res://assets/characters/penguin_hero.png")
	shinchan_tex = load("res://assets/characters/shinchan_hero.png")

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
			if state_timer >= 12.0:
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
			dialogue_label.text = "Lumi: â€œPsstâ€¦ wait! There's one more little surprise for you!â€"
			AudioManager.play_voice_file("res://assets/audio/lumi_surprise_open.wav",
				"Psstâ€¦ wait! There's one more little surprise for you!", 4.0)
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
			dialogue_label.text = "Lumi: â€œ" + EXACT_FINAL_QUOTE + "â€"
			AudioManager.play_voice_file("res://assets/audio/lumi_final_quote.wav",
				EXACT_FINAL_QUOTE, 11.0)

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
			AudioManager.play_sfx("legend_fanfare")

func _on_skip_pressed() -> void:
	AudioManager.stop_voice()
	_enter_state(CinematicState.REWARD_SCREEN)

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

	# C. Dreamy Pastel Rainbow Archway & Glowing Golden Door
	var center := Vector2(640.0, 420.0)
	var door_glow: float = absf(sin(time_elapsed * 2.5)) * 0.25 + 0.75
	var pastel_rainbow := [
		Color(1.0, 0.68, 0.78), # Pastel Rose
		Color(1.0, 0.82, 0.68), # Pastel Peach
		Color(1.0, 0.95, 0.72), # Pastel Buttercream
		Color(0.78, 0.95, 0.82), # Pastel Sage Green
		Color(0.72, 0.90, 1.00), # Pastel Sky Blue
		Color(0.88, 0.78, 0.98)  # Pastel Lavender
	]
	for i in range(pastel_rainbow.size()):
		var r := 180.0 + i * 16.0
		var c: Color = pastel_rainbow[i] * door_glow
		c.a = 0.82
		wonderland_canvas.draw_arc(center, r, PI, TAU, 36, c, 13.0)

	# Glowing Golden Door
	wonderland_canvas.draw_rect(Rect2(center + Vector2(-95, -175), Vector2(190, 175)), Color(1.0, 0.92, 0.65, 0.92))
	wonderland_canvas.draw_rect(Rect2(center + Vector2(-85, -165), Vector2(170, 165)), Color(1.0, 0.97, 0.82, 0.96))
	# Subtle door panel trims
	wonderland_canvas.draw_rect(Rect2(center + Vector2(-75, -155), Vector2(65, 68)), Color(1.0, 0.90, 0.70, 0.6))
	wonderland_canvas.draw_rect(Rect2(center + Vector2(10, -155), Vector2(65, 68)), Color(1.0, 0.90, 0.70, 0.6))
	wonderland_canvas.draw_rect(Rect2(center + Vector2(-75, -75), Vector2(65, 68)), Color(1.0, 0.90, 0.70, 0.6))
	wonderland_canvas.draw_rect(Rect2(center + Vector2(10, -75), Vector2(65, 68)), Color(1.0, 0.90, 0.70, 0.6))

	# D. Characters Gathered Together
	if current_state >= CinematicState.SCENE_B_EVERYONE_APPEARS:
		# 1. Cute Baby Penguin (Left)
		var p_pos := Vector2(340.0 + sin(time_elapsed * 4.0) * 12.0, 500.0)
		# Soft ground contact shadow
		wonderland_canvas.draw_ellipse(Vector2(p_pos.x, 575.0), 45.0, 14.0, Color(0.3, 0.2, 0.35, 0.28))
		if penguin_tex:
			var p_w := 140.0
			var p_h := 140.0 * (float(penguin_tex.get_height()) / float(penguin_tex.get_width()))
			wonderland_canvas.draw_texture_rect(penguin_tex, Rect2(p_pos.x - p_w * 0.5, p_pos.y - p_h * 0.5, p_w, p_h), false)

		# 2. Shinchan (Right)
		var c_pos := Vector2(940.0 + sin(time_elapsed * 5.0) * -12.0, 490.0)
		# Soft ground contact shadow
		wonderland_canvas.draw_ellipse(Vector2(c_pos.x, 575.0), 45.0, 14.0, Color(0.3, 0.2, 0.35, 0.28))
		if shinchan_tex:
			var s_w := 130.0
			var s_h := 130.0 * (float(shinchan_tex.get_height()) / float(shinchan_tex.get_width()))
			wonderland_canvas.draw_texture_rect(shinchan_tex, Rect2(c_pos.x - s_w * 0.5, c_pos.y - s_h * 0.5, s_w, s_h), false)

		# 3. Magical Guide Lumi (Center Hovering)
		var lumi_pos := Vector2(640.0, 310.0 + sin(time_elapsed * 3.5) * 16.0)
		var aura_glow := Color(1.0, 0.95, 0.7, 0.40 + sin(time_elapsed * 6.0) * 0.15)
		wonderland_canvas.draw_circle(lumi_pos, 48.0, aura_glow)
		wonderland_canvas.draw_circle(lumi_pos, 32.0, Color(1.0, 1.0, 0.85, 0.6))
		var wing_f := sin(time_elapsed * 12.0) * 8.0
		wonderland_canvas.draw_ellipse(lumi_pos + Vector2(-24, -10), 18.0, 28.0 + wing_f, Color(0.85, 0.95, 1.0, 0.75))
		wonderland_canvas.draw_ellipse(lumi_pos + Vector2(24, -10), 18.0, 28.0 + wing_f, Color(0.85, 0.95, 1.0, 0.75))
		wonderland_canvas.draw_ellipse(lumi_pos + Vector2(0, 12), 14.0, 20.0, Color(0.55, 0.88, 0.98))
		wonderland_canvas.draw_circle(lumi_pos + Vector2(0, -12), 16.0, Color(1.0, 0.90, 0.82))
		wonderland_canvas.draw_circle(lumi_pos + Vector2(-5, -14), 2.5, Color(0.2, 0.4, 0.7))
		wonderland_canvas.draw_circle(lumi_pos + Vector2(5, -14), 2.5, Color(0.2, 0.4, 0.7))
		wonderland_canvas.draw_arc(lumi_pos + Vector2(0, -8), 4.0, 0.2, 2.9, 8, Color(0.9, 0.4, 0.5), 1.5)
		wonderland_canvas.draw_line(lumi_pos + Vector2(14, 8), lumi_pos + Vector2(34, -8), Color.GOLD, 3.0)
		wonderland_canvas.draw_circle(lumi_pos + Vector2(34, -8), 5.5, Color.WHITE)

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

	# F. Interactive Fluttering Butterflies (Spawned by Hand Motion)
	for bf in interactive_butterflies:
		var bp: Vector2 = bf["pos"]
		var bcol: Color = bf["color"]
		var balp: float = clampf(bf["life"] / 2.2, 0.0, 1.0)
		var flap := absf(sin(time_elapsed * 12.0 + bf["seed"])) * 10.0
		wonderland_canvas.draw_ellipse(bp - Vector2(8, 0), 10.0, flap, Color(bcol.r, bcol.g, bcol.b, balp * 0.9))
		wonderland_canvas.draw_ellipse(bp + Vector2(8, 0), 10.0, flap, Color(bcol.r, bcol.g, bcol.b, balp * 0.9))
		wonderland_canvas.draw_circle(bp, 2.8, Color(0.3, 0.2, 0.35, balp))


