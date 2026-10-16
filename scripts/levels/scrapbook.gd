extends Control

## WIGGLE WARS! — Sticker Scrapbook & Memory Album 📖✨
## Displays persistent memories collected across all realms with
## cute Pinterest journal aesthetic, paper textures, and all 7 real memory cards.

@onready var sticker_container: HBoxContainer = $Margin/VBox/Scroll/HBox
@onready var progress_label: Label = $Margin/VBox/HeaderBox/ProgressLabel
@onready var back_btn: Button = $Margin/VBox/BottomBar/BackBtn
@onready var play_again_btn: Button = get_node_or_null("Margin/VBox/BottomBar/PlayAgainBtn")

const MEMORIES: Dictionary = {
	1: {
		"title": "Garden Memory 🌸",
		"level": "Level 1: Face Frenzy",
		"memory": "Remember that radiant smile that bloomed pink tulips across the sunny grass? Pure sunshine!",
		"card_tex": "res://assets/sprites/memory_card_1.png",
		"tag": "GARDEN MEMORY"
	},
	2: {
		"title": "Lake Memory 🍉",
		"level": "Level 2: Fruit Ninja",
		"memory": "Lightning-fast air slices sent tropical fruits flying and juicy splashes soaring across the lake!",
		"card_tex": "res://assets/sprites/memory_card_2.png",
		"tag": "LAKE MEMORY"
	},
	3: {
		"title": "Arctic Memory 🐧",
		"level": "Level 3: Waddle Wars",
		"memory": "Leaning, jumping, and belly-sliding together with our adorable baby penguin in his cozy beanie!",
		"card_tex": "res://assets/sprites/memory_card_3.png",
		"tag": "ARCTIC MEMORY"
	},
	4: {
		"title": "Theater Memory 🎭",
		"level": "Level 4: Copycat Chaos",
		"memory": "Striking the hero pose, waving hello, and dancing wildly with Shinchan on the grand stage!",
		"card_tex": "res://assets/sprites/memory_card_4.png",
		"tag": "THEATER MEMORY"
	},
	5: {
		"title": "Carnival Memory 🎡",
		"level": "Level 5: Lucky Chaos Wheel",
		"memory": "Braving the giant pink carnival wheel, conquering silly challenges, and claiming party treats!",
		"card_tex": "res://assets/sprites/memory_card_5.png",
		"tag": "CARNIVAL MEMORY"
	},
	6: {
		"title": "Wonderland Memory 🌈",
		"level": "Secret Surprise Wonderland",
		"memory": "The magical golden door opened into Surprise Wonderland with Lumi and the Angel!",
		"card_tex": "res://assets/sprites/memory_card_6.png",
		"tag": "WONDERLAND MEMORY"
	},
	7: {
		"title": "Legend Memory 🏆",
		"level": "Master Realm",
		"memory": "All 5 realms conquered! A true Wiggle Wars legend and superstar of boundless joy!",
		"card_tex": "res://assets/sprites/memory_card_7.png",
		"tag": "LEGEND MEMORY"
	}
}

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again_pressed)
	
	_populate_cards()
	_update_header()
	
	AudioManager.play_sfx("chime")

func _populate_cards() -> void:
	if not sticker_container:
		return
		
	# Clear any previous children
	for child in sticker_container.get_children():
		child.queue_free()
		
	for i in range(1, 8):
		var card := _build_card(i)
		sticker_container.add_child(card)

func _build_card(mem_num: int) -> Control:
	var mem: Dictionary = MEMORIES[mem_num]
	var unlocked: bool = StickerManager.is_sticker_unlocked(mem_num)
	
	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(196, 360)
	
	var sb := StyleBoxFlat.new()
	if unlocked:
		sb.bg_color = Color(1.0, 0.98, 0.96, 0.96)
		sb.border_color = Color(0.95, 0.70, 0.82, 1.0)
		sb.set_border_width_all(3)
		sb.shadow_color = Color(0.9, 0.65, 0.8, 0.35)
		sb.shadow_size = 8
	else:
		sb.bg_color = Color(0.92, 0.90, 0.94, 0.80)
		sb.border_color = Color(0.78, 0.75, 0.82, 0.6)
		sb.set_border_width_all(2)
		sb.shadow_color = Color(0.6, 0.6, 0.65, 0.1)
		sb.shadow_size = 4
	sb.set_corner_radius_all(16)
	card_panel.add_theme_stylebox_override("panel", sb)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Card Artwork Texture Rect
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(182, 348)
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var card_path: String = mem.get("card_tex", "")
	if ResourceLoader.exists(card_path):
		tex_rect.texture = load(card_path)
		if unlocked:
			tex_rect.modulate = Color.WHITE
		else:
			tex_rect.modulate = Color(0.4, 0.4, 0.45, 0.45)
	
	vbox.add_child(tex_rect)
	return card_panel

func _update_header() -> void:
	if progress_label:
		var count := StickerManager.get_unlocked_count()
		progress_label.text = "MEMORIES UNLOCKED: %d / 7  🌈" % count
		if count >= 5:
			progress_label.text = "ALL REALMS CONQUERED! WIGGLE WARS LEGEND! 🏆✨"

func _on_back_pressed() -> void:
	AudioManager.play_sfx("boing")
	GameManager.return_to_main_menu()

func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.reset_game_state()
	GameManager.load_level(1)
