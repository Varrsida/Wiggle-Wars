extends Control

## WIGGLE WARS! — Secret Final Surprise 🎁🌈
## Surprise Wonderland — The Hidden Ending
## Cinematic sequence:
## Scene A: Glowing rainbow door opens
## Scene B: Characters appear (Baby Penguin, Shinchan, Flowers, Fruits)
## Scene C: Big Wonderland celebration with confetti
## Scene D: Lumi delivers exact fixed final quote with subtitles & angelic voice
## Exact final on-screen message revealed typewriter-style:
## "YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. 🌈"
## Final Reward Screen: "WIGGLE WARS LEGEND! 🏆" with actual score and working buttons!

@onready var background_panel: Panel = $Background
@onready var wonderland_canvas: Node2D = $WonderlandCanvas
@onready var door_node: Node2D = $WonderlandCanvas/RainbowDoor
@onready var confetti_particles: CPUParticles2D = $ConfettiParticles
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/Margin/Label
@onready var final_message_label: Label = $FinalMessageLabel
@onready var reward_screen: PanelContainer = $RewardScreen
@onready var final_score_label: Label = $RewardScreen/Margin/VBox/ScoreLabel
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

func _ready() -> void:
	# STRICT SAFEGUARD: Verify all 5 levels completed and Level 5 results acknowledged!
	if not GameManager.can_unlock_secret_ending():
		printerr("[SecretEnding] Violation: Triggered without genuine completion of all 5 levels!")
		GameManager.return_to_main_menu()
		return

	dialogue_panel.visible = false
	final_message_label.visible = false
	reward_screen.visible = false
	
	_enter_state(CinematicState.OPENING_SURPRISE)

func _process(delta: float) -> void:
	time_elapsed += delta
	state_timer += delta
	
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
				
	queue_redraw()

func _enter_state(new_state: CinematicState) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		CinematicState.OPENING_SURPRISE:
			dialogue_panel.visible = true
			dialogue_label.text = "Lumi: “Psst… wait! There's one more little surprise for you!”"
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
			dialogue_label.text = "Lumi: “" + EXACT_FINAL_QUOTE + "”"
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
			final_score_label.text = "FINAL SCORE: %d POINTS" % GameManager.total_score
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

func _draw() -> void:
	# Draw Surprise Wonderland celebratory environment
	# 1. Rainbow Archway
	var center := Vector2(640.0, 420.0)
	var door_glow: float = absf(sin(time_elapsed * 3.0)) * 0.3 + 0.7
	var rainbow_colors := [
		Color(1, 0.2, 0.2), Color(1, 0.6, 0.1), Color(1, 1, 0.2),
		Color(0.2, 0.9, 0.3), Color(0.2, 0.7, 1), Color(0.6, 0.3, 0.9)
	]
	for i in range(rainbow_colors.size()):
		var r := 180.0 + i * 16.0
		var c: Color = rainbow_colors[i] * door_glow
		draw_arc(center, r, PI, TAU, 32, c, 14.0)

	# 2. Glowing Golden Door
	draw_rect(Rect2(center + Vector2(-100, -180), Vector2(200, 180)), Color(1.0, 0.88, 0.4, 0.9))
	draw_rect(Rect2(center + Vector2(-90, -170), Vector2(180, 170)), Color(1.0, 0.95, 0.7, 0.95))

	if current_state >= CinematicState.SCENE_B_EVERYONE_APPEARS:
		# Draw Characters All Together!
		
		# A. Cute Baby Penguin (Hero of Waddle Wars)
		var p_pos := Vector2(360.0 + sin(time_elapsed * 4.0) * 15.0, 520.0)
		# Feet
		draw_ellipse(p_pos + Vector2(-12, 18), 10.0, 5.0, Color(1.0, 0.55, 0.1))
		draw_ellipse(p_pos + Vector2(12, 18), 10.0, 5.0, Color(1.0, 0.55, 0.1))
		# Body
		draw_ellipse(p_pos, 32.0, 40.0, Color(0.12, 0.14, 0.2))
		draw_ellipse(p_pos + Vector2(0, 4), 22.0, 32.0, Color.WHITE)
		# Flippers waving in victory
		draw_ellipse(p_pos + Vector2(-30, -10), 8.0, 18.0, Color(0.12, 0.14, 0.2))
		draw_ellipse(p_pos + Vector2(30, -10), 8.0, 18.0, Color(0.12, 0.14, 0.2))
		# Head & Beak
		draw_circle(p_pos + Vector2(0, -35), 24.0, Color(0.12, 0.14, 0.2))
		draw_circle(p_pos + Vector2(-8, -38), 6.0, Color.WHITE)
		draw_circle(p_pos + Vector2(8, -38), 6.0, Color.WHITE)
		draw_circle(p_pos + Vector2(-7, -38), 3.0, Color.BLACK)
		draw_circle(p_pos + Vector2(9, -38), 3.0, Color.BLACK)
		draw_polygon(PackedVector2Array([
			p_pos + Vector2(0, -28), p_pos + Vector2(-5, -34), p_pos + Vector2(5, -34)
		]), PackedColorArray([Color(1.0, 0.6, 0.1)]))

		# B. Shinchan / Workshop Cartoon Star
		var c_pos := Vector2(920.0 + sin(time_elapsed * 5.0) * -15.0, 520.0)
		draw_rect(Rect2(c_pos + Vector2(-25, 15), Vector2(50, 35)), Color(1.0, 0.9, 0.1))
		draw_polygon(PackedVector2Array([
			c_pos + Vector2(-30, 20), c_pos + Vector2(30, 20),
			c_pos + Vector2(24, -30), c_pos + Vector2(-24, -30)
		]), PackedColorArray([Color(0.95, 0.15, 0.15)]))
		# Arms raised in victory
		draw_line(c_pos + Vector2(-24, -20), c_pos + Vector2(-45, -50), Color(1.0, 0.8, 0.65), 10.0)
		draw_line(c_pos + Vector2(24, -20), c_pos + Vector2(45, -50), Color(1.0, 0.8, 0.65), 10.0)
		# Head
		var head_p := c_pos + Vector2(0, -55)
		draw_ellipse(head_p, 34.0, 28.0, Color(1.0, 0.82, 0.68))
		draw_line(head_p + Vector2(-20, -12), head_p + Vector2(-5, -15), Color.BLACK, 6.0)
		draw_line(head_p + Vector2(5, -15), head_p + Vector2(20, -12), Color.BLACK, 6.0)
		draw_ellipse(head_p + Vector2(-12, -4), 7.0, 9.0, Color.BLACK)
		draw_ellipse(head_p + Vector2(14, -4), 7.0, 9.0, Color.BLACK)
		draw_arc(head_p + Vector2(2, 10), 12.0, 0.1, 2.9, 12, Color(0.8, 0.2, 0.2), 3.0)

		# C. Magical Guide Lumi (Floating in Center)
		var lumi_pos := Vector2(640.0, 310.0 + sin(time_elapsed * 3.5) * 16.0)
		# Glowing Aura
		var aura_glow := Color(1.0, 0.95, 0.6, 0.35 + sin(time_elapsed * 6.0) * 0.15)
		draw_circle(lumi_pos, 46.0, aura_glow)
		draw_circle(lumi_pos, 32.0, Color(1.0, 1.0, 0.8, 0.5))
		# Fairy Wings
		var wing_f := sin(time_elapsed * 12.0) * 8.0
		draw_ellipse(lumi_pos + Vector2(-22, -10), 16.0, 28.0 + wing_f, Color(0.8, 0.95, 1.0, 0.7))
		draw_ellipse(lumi_pos + Vector2(22, -10), 16.0, 28.0 + wing_f, Color(0.8, 0.95, 1.0, 0.7))
		# Sweet fairy body
		draw_ellipse(lumi_pos + Vector2(0, 12), 14.0, 20.0, Color(0.4, 0.85, 0.95))
		draw_circle(lumi_pos + Vector2(0, -12), 16.0, Color(1.0, 0.88, 0.78))
		# Gentle kind eyes & smile
		draw_circle(lumi_pos + Vector2(-5, -14), 2.5, Color(0.2, 0.4, 0.7))
		draw_circle(lumi_pos + Vector2(5, -14), 2.5, Color(0.2, 0.4, 0.7))
		draw_arc(lumi_pos + Vector2(0, -8), 4.0, 0.2, 2.9, 8, Color(0.9, 0.4, 0.5), 1.5)
		# Sparkle wand
		draw_line(lumi_pos + Vector2(14, 8), lumi_pos + Vector2(32, -8), Color.GOLD, 3.0)
		draw_circle(lumi_pos + Vector2(32, -8), 5.0, Color.WHITE)

		# D. Floating Celebratory Props (Flowers, Fruit, Balloons)
		draw_circle(Vector2(200, 380 + sin(time_elapsed * 2.0) * 10.0), 22.0, Color(1.0, 0.4, 0.6)) # Flower
		draw_circle(Vector2(1080, 360 + cos(time_elapsed * 2.5) * 12.0), 24.0, Color(0.2, 0.7, 0.3)) # Watermelon
