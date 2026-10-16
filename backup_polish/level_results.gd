extends Control

## WIGGLE WARS! — Level Results Screen
## Displays level completion achievements (zero score references)
## and controls progression to the next level or unlocks the secret ending.

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var badge_label: Label = $Panel/VBox/BadgeLabel
@onready var details_label: Label = $Panel/VBox/DetailsLabel
@onready var next_btn: Button = $Panel/VBox/Buttons/NextBtn
@onready var replay_btn: Button = $Panel/VBox/Buttons/ReplayBtn
@onready var menu_btn: Button = $Panel/VBox/Buttons/MenuBtn

var current_lvl: int = 1

func _ready() -> void:
	current_lvl = GameManager.current_level
	
	title_label.text = "%s COMPLETE! 🎉" % GameManager.LEVEL_NAMES.get(current_lvl, "LEVEL")
	status_label.text = "⏱️ 45 SECONDS CONQUERED! 🏆"
	
	if StickerManager:
		var st_data: Dictionary = StickerManager.get_sticker_data(current_lvl)
		badge_label.text = "🌟 STICKER COLLECTED: %s (Saved to Scrapbook!)" % st_data.get("name", "Sticker")
	else:
		badge_label.text = "🌟 PARTY PERFORMANCE: SPECTACULAR!"
	
	_populate_details()
	AudioManager.play_sfx("combo")

func _populate_details() -> void:
	match current_lvl:
		1:
			details_label.text = "🌸 Magical Garden Bloomed!\n• Expressions Performed: Smiles, Bubbles, Star Bursts\n• Sleepy garden twilight & magical wind gusts activated!\n• All 5 facial expressions conquered!"
			next_btn.text = "Next: Level 2 (Fruit Ninja) 🍉 ➔"
		2:
			var fruits_count := GameManager.level2_fruits_sliced
			details_label.text = "🍉 Tropical Arena Sliced!\n• Total Fruits Sliced: %d 🍉\n• Real Hand Swipes Performed Across 45 Seconds!\n• Flying Watermelons, Pineapples, Bananas & Sus Strawberries sliced!\n• Master of the Blade!" % fruits_count
			next_btn.text = "Next: Level 3 (Waddle Wars) 🐧 ➔"
		3:
			var crystals := GameManager.level3_crystals_collected
			var fish := GameManager.level3_fish_collected
			details_label.text = "🐧 Cute Penguin Hero Guided!\n• Crystals Gathered: %d 💎  |  Fish Caught: %d 🐟\n• Leans, Jumps, Slides, Balance & Squat poses executed!\n• Penguin hero safely reached the top!" % [crystals, fish]
			next_btn.text = "Next: Level 4 (Copycat Chaos) 🎭 ➔"
		4:
			details_label.text = "🎭 Shinchan's Workshop Rocked!\n• Waves, Dances, Funny Poses & Real Voice Speech completed!\n• Stage audience thoroughly entertained!\n• Workshop superstar!"
			next_btn.text = "Next: Level 5 (Lucky Chaos Wheel) 🎡 ➔"
		5:
			var outcome := GameManager.level5_wheel_outcome
			details_label.text = "🎡 Carnival Prize Wheel Completed!\n• Slices Spun: %s\n• All 5 Levels Genuinely Conquered across full 45s sessions!" % outcome
			next_btn.text = "Acknowledge & Continue 🌟"

func _on_next_pressed() -> void:
	AudioManager.play_sfx("chime")
	if current_lvl < 5:
		GameManager.load_level(current_lvl + 1)
	elif current_lvl == 5:
		# Player acknowledged normal Level 5 results!
		GameManager.level5_results_acknowledged = true
		if GameManager.can_unlock_secret_ending():
			GameManager.load_secret_ending()
		else:
			GameManager.return_to_main_menu()

func _on_replay_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.load_level(current_lvl)

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.return_to_main_menu()
