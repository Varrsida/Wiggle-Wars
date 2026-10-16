extends Control

## WIGGLE WARS! — Sticker Scrapbook & Memory Album 📖✨
## Displays persistent stickers collected across all 5 levels with
## paper/pastel Pinterest aesthetic, warm memory cards, and unlock progress.

@onready var sticker_container: HBoxContainer = $Margin/VBox/Scroll/HBox
@onready var progress_label: Label = $Margin/VBox/HeaderBox/ProgressLabel
@onready var back_btn: Button = $Margin/VBox/BottomBar/BackBtn

const MEMORIES: Dictionary = {
	1: {
		"title": "Radiant Bloom 🌸",
		"level": "Level 1: Face Frenzy",
		"memory": "Remember that radiant smile that bloomed pink tulips across the sunny grass? Pure pure sunshine!",
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
		"memory": "Leaning, jumping, and belly-sliding together with our adorable baby penguin across icy peaks!",
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
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	
	_populate_cards()
	_update_header()
	
	AudioManager.play_sfx("chime")

func _populate_cards() -> void:
	if not sticker_container:
		return
		
	# Clear any dummy children
	for child in sticker_container.get_children():
		child.queue_free()
		
	for i in range(1, 6):
		var card := _build_card(i)
		sticker_container.add_child(card)

func _build_card(level_num: int) -> Control:
	var mem: Dictionary = MEMORIES[level_num]
	var unlocked: bool = StickerManager.is_sticker_unlocked(level_num)
	var st_data: Dictionary = StickerManager.get_sticker_data(level_num)
	
	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(230, 460)
	
	var sb := StyleBoxFlat.new()
	if unlocked:
		sb.bg_color = Color(1.0, 0.98, 0.95, 0.96)
		sb.border_color = Color(0.92, 0.65, 0.78, 1.0)
		sb.set_border_width_all(3)
		sb.shadow_color = Color(0.85, 0.65, 0.75, 0.35)
		sb.shadow_size = 10
	else:
		sb.bg_color = Color(0.92, 0.90, 0.94, 0.85)
		sb.border_color = Color(0.75, 0.72, 0.80, 0.8)
		sb.set_border_width_all(2)
		sb.shadow_color = Color(0.6, 0.6, 0.65, 0.15)
		sb.shadow_size = 4
	sb.set_corner_radius_all(18)
	card_panel.add_theme_stylebox_override("panel", sb)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Tag / Level Label
	var tag_label := Label.new()
	tag_label.text = mem["tag"]
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.add_theme_font_size_override("font_size", 11)
	tag_label.add_theme_color_override("font_color", Color(0.7, 0.45, 0.55) if unlocked else Color(0.5, 0.5, 0.55))
	vbox.add_child(tag_label)
	
	# Sticker Texture Rect
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(140, 140)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if unlocked and ResourceLoader.exists(mem["icon"]):
		tex_rect.texture = load(mem["icon"])
		tex_rect.modulate = Color.WHITE
	else:
		if ResourceLoader.exists(mem["icon"]):
			tex_rect.texture = load(mem["icon"])
			tex_rect.modulate = Color(0.3, 0.3, 0.35, 0.4)
	vbox.add_child(tex_rect)
	
	# Title
	var title_lbl := Label.new()
	title_lbl.text = mem["title"] if unlocked else "🔒 Locked Sticker"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.28, 0.15, 0.25) if unlocked else Color(0.5, 0.48, 0.55))
	vbox.add_child(title_lbl)
	
	# Memory Text
	var mem_lbl := Label.new()
	if unlocked:
		mem_lbl.text = mem["memory"]
	else:
		mem_lbl.text = "Complete %s (45 seconds) to unlock this cute sticker and memory!" % mem["level"]
	mem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mem_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mem_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mem_lbl.add_theme_font_size_override("font_size", 12)
	mem_lbl.add_theme_color_override("font_color", Color(0.38, 0.30, 0.35) if unlocked else Color(0.58, 0.55, 0.60))
	vbox.add_child(mem_lbl)
	
	# Status Footer Badge
	var status_lbl := Label.new()
	if unlocked:
		var unlock_time: String = st_data.get("unlocked_at", "")
		status_lbl.text = "✨ UNLOCKED"
		status_lbl.add_theme_color_override("font_color", Color(0.2, 0.75, 0.4))
	else:
		status_lbl.text = "🔒 LOCKED"
		status_lbl.add_theme_color_override("font_color", Color(0.65, 0.4, 0.4))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status_lbl)
	
	return card_panel

func _update_header() -> void:
	if progress_label:
		var count := StickerManager.get_unlocked_count()
		progress_label.text = "MEMORIES UNLOCKED: %d / 5  🌈" % count
		if count == 5:
			progress_label.text = "ALL 5 MEMORIES UNLOCKED! WIGGLE WARS LEGEND! 🏆✨"

func _on_back_pressed() -> void:
	AudioManager.play_sfx("boing")
	GameManager.return_to_main_menu()
