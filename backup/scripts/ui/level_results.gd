extends Control

## WIGGLE WARS! — Level Results Screen
## Displays level score, achievements, and controls progression to the next level
## or triggers the secret ending if Level 5 results are acknowledged.

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var level_score_label: Label = $Panel/VBox/LevelScoreLabel
@onready var total_score_label: Label = $Panel/VBox/TotalScoreLabel
@onready var details_label: Label = $Panel/VBox/DetailsLabel
@onready var next_btn: Button = $Panel/VBox/Buttons/NextBtn
@onready var replay_btn: Button = $Panel/VBox/Buttons/ReplayBtn
@onready var menu_btn: Button = $Panel/VBox/Buttons/MenuBtn

var current_lvl: int = 1

func _ready() -> void:
	current_lvl = GameManager.current_level
	var l_score: int = GameManager.level_scores.get(current_lvl, 0)
	var t_score: int = GameManager.total_score
	
	title_label.text = "%s COMPLETE! 🎉" % GameManager.LEVEL_NAMES.get(current_lvl, "LEVEL")
	level_score_label.text = "Level Score: %d points" % l_score
	total_score_label.text = "Total Wiggle Score: %d points" % t_score
	
	_populate_details()
	AudioManager.play_sfx("combo")

func _populate_details() -> void:
	match current_lvl:
		1:
			details_label.text = "🌸 Magical Garden Bloomed!\n• Expressions Made: Smiles, Bubbles, Star Bursts\n• Sleepy garden and wind gusts activated!"
			next_btn.text = "Next: Level 2 (Fruit Ninja) 🍉 ➔"
		2:
			details_label.text = "🍉 Tropical Arena Sliced!\n• Real Hand Swipes Verified\n• Combos, Watermelon Fountain, Banana Split & Sus Strawberry sliced!"
			next_btn.text = "Next: Level 3 (Waddle Wars) 🐧 ➔"
		3:
			details_label.text = "🐧 Cute Penguin Hero Guided!\n• Leans, Jumps, Slides, Balance, and Squat poses matched!\n• Crystals collected across snowy mountains!"
			next_btn.text = "Next: Level 4 (Copycat Chaos) 🎭 ➔"
		4:
			details_label.text = "🎭 Shinchan's Workshop Rocked!\n• Waves, Dances, Funny Poses, and Real Speech Imitation completed!\n• Reaction meter filled to maximum!"
			next_btn.text = "Next: Level 5 (Lucky Chaos Wheel) 🎡 ➔"
		5:
			var outcome := GameManager.level5_wheel_outcome
			details_label.text = "🎡 Carnival Prize Wheel Completed!\n• Slices Spun: %s\n• All 5 Levels Genuinely Conquered!" % outcome
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
