extends Control

## WIGGLE WARS! — Level Results & Next Level Entry System
## Features:
## 1. Standalone Results Screen with actual tracked stats and no score references.
## 2. Sparkling, glittering celebration effects (Level 3 icy glitter, Level 4 golden starbursts).
## 3. Strict separation: Results Panel must be closed before Entry Panel is shown.
## 4. Standalone Next Level Entry Screen with explicit "Start Level X" button.

@onready var results_panel: PanelContainer = $ResultsPanel
@onready var entry_panel: PanelContainer = $EntryPanel

@onready var title_label: Label = $ResultsPanel/VBox/TitleLabel
@onready var status_label: Label = $ResultsPanel/VBox/StatusLabel
@onready var badge_label: Label = $ResultsPanel/VBox/BadgeLabel
@onready var details_label: Label = $ResultsPanel/VBox/DetailsLabel
@onready var collectibles_row: HBoxContainer = $ResultsPanel/VBox/CollectiblesRow
@onready var crystal_count_lbl: Label = $ResultsPanel/VBox/CollectiblesRow/CrystalCard/VBox/Count
@onready var fish_count_lbl: Label = $ResultsPanel/VBox/CollectiblesRow/FishCard/VBox/Count
@onready var crystal_card: PanelContainer = $ResultsPanel/VBox/CollectiblesRow/CrystalCard
@onready var fish_card: PanelContainer = $ResultsPanel/VBox/CollectiblesRow/FishCard

@onready var continue_btn: Button = $ResultsPanel/VBox/Buttons/ContinueBtn
@onready var replay_btn: Button = $ResultsPanel/VBox/Buttons/ReplayBtn
@onready var menu_btn: Button = $ResultsPanel/VBox/Buttons/MenuBtn

@onready var entry_next_title: Label = $EntryPanel/VBox/NextTitle
@onready var entry_next_subtitle: Label = $EntryPanel/VBox/NextSubtitle
@onready var entry_briefing_label: Label = $EntryPanel/VBox/BriefingLabel
@onready var start_level_btn: Button = $EntryPanel/VBox/EntryButtons/StartLevelBtn

@onready var confetti_particles: CPUParticles2D = $ConfettiParticles
@onready var icy_glitter: CPUParticles2D = $IcyGlitterParticles
@onready var golden_glitter: CPUParticles2D = $GoldenGlitterParticles

var current_lvl: int = 1

func _ready() -> void:
	current_lvl = GameManager.current_level
	
	results_panel.visible = true
	entry_panel.visible = false
	collectibles_row.visible = false
	
	title_label.text = "SUCCESSFULLY COMPLETED! 🎉"
	
	# Configure Level-Specific Results with Standard 5-Point Hierarchy
	match current_lvl:
		1:
			status_label.text = "Challenge Completed: Fruit Ninja 🍉"
			status_label.add_theme_color_override("font_color", Color(0.9, 0.45, 0.1))
			var fruits_count := GameManager.level1_fruits_sliced
			details_label.text = "Total Fruits Sliced: %d 🍉\nFast blade combos and real hand swipes executed!" % fruits_count
			badge_label.text = "Fantastic slicing! You conquered the tropical arena!"
			continue_btn.text = "CONTINUE ➔"

		2:
			status_label.text = "Challenge Completed: Waddle Wars 🐧"
			status_label.add_theme_color_override("font_color", Color(0.1, 0.5, 0.9))
			var crystals := GameManager.level2_crystals_collected
			var fish := GameManager.level2_fish_collected
			var total := crystals + fish
			collectibles_row.visible = true
			crystal_count_lbl.text = str(crystals)
			fish_count_lbl.text = str(fish)
			_animate_collectible_card(crystal_card, 0.0)
			_animate_collectible_card(fish_card, 0.15)
			icy_glitter.emitting = true
			details_label.text = "Crystals: %d 💎  |  Icy Fish: %d 🐟  |  Total Gathered: %d" % [crystals, fish, total]
			badge_label.text = "Quack & waddle! The cutest arctic moves on the snowy peaks!"
			continue_btn.text = "CONTINUE ➔"

		3:
			status_label.text = "Challenge Completed: Face Frenzy 🌸"
			status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.75))
			details_label.text = "Facial Actions Completed: 5 / 5 Expressions Conquered ✔\nRadiant Smiles, Bubbles, Star Bursts, Twilight & Wind Gusts!"
			badge_label.text = "Radiant smiles and wonderful energy bloomed the magical garden!"
			continue_btn.text = "CONTINUE ➔"

		4:
			status_label.text = "Challenge Completed: Shin Chan Dialogue & Dance 🎭"
			status_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.15))
			golden_glitter.emitting = true
			details_label.text = "Stage Performance: Superstar Moves & Dialogue Matched ✔\nInteractive chatbot and dances performed with Shin Chan!"
			badge_label.text = "Balle Balle! Shin Chan is thrilled with your superstar energy!"
			continue_btn.text = "CONTINUE ➔"

		5:
			var outcome := GameManager.level5_wheel_outcome
			status_label.text = "Challenge Completed: %s" % (outcome if outcome != "" else "Lucky Chaos Wheel 🎡")
			status_label.add_theme_color_override("font_color", Color(0.85, 0.6, 0.1))
			details_label.text = "Carnival Challenge: Full 20-Second Round Conquered ✔\nGenuine computer-vision tracking completed!"
			badge_label.text = "Spectacular carnival performance! Pure champion energy!"
			continue_btn.text = "CONTINUE ➔"

	AudioManager.play_sfx("combo")

func _animate_collectible_card(card: Control, delay: float) -> void:
	if not card:
		return
	card.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(card, "scale", Vector2(1.15, 1.15), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("chime")
	
	if current_lvl < 5:
		# Step 5: Close the results panel completely
		results_panel.visible = false
		icy_glitter.emitting = false
		golden_glitter.emitting = false
		
		# Step 6: Show the separate Next-Level Entry Panel
		entry_panel.visible = true
		_populate_entry_panel(current_lvl + 1)
	elif current_lvl == 5:
		GameManager.level5_results_acknowledged = true
		if GameManager.can_unlock_secret_ending():
			GameManager.load_secret_ending()
		else:
			GameManager.return_to_main_menu()

func _populate_entry_panel(next_lvl: int) -> void:
	match next_lvl:
		2:
			entry_next_title.text = "LEVEL 2: WADDLE WARS 🐧"
			entry_next_subtitle.text = "Icy Mountain Expedition"
			entry_briefing_label.text = "• Guide our cute baby penguin wearing his blue beanie!\n• Lean your body LEFT or RIGHT to steer along the snowy paths.\n• Raise BOTH HANDS to leap over deep ice crevices.\n• SQUAT DOWN to belly-slide smoothly under frozen crystal arches.\n• Collect shimmering crystals 💎 and fresh icy fish 🐟!"
			start_level_btn.text = "▶️ START LEVEL 2"

		3:
			entry_next_title.text = "LEVEL 3: FACE FRENZY 🌸"
			entry_next_subtitle.text = "Enchanted Flower Garden"
			entry_briefing_label.text = "• Use your facial expressions in front of the webcam!\n• Radiant Smile blooms flowers, Open Mouth blows bubbles!\n• Eyebrows raise star bursts, Sleepy Face triggers twilight garden!\n• Surprised Face unleashes magical wind gusts!"
			start_level_btn.text = "▶️ START LEVEL 3"

		4:
			entry_next_title.text = "LEVEL 4: COPYCAT CHAOS 🎭"
			entry_next_subtitle.text = "Shinchan's Interactive Chatbot Stage"
			entry_briefing_label.text = "• Meet Shinchan in his original red T-shirt on center stage!\n• Interactive Chatbot: Type messages or speak with him in Tamil & English!\n• Ask him to Dance, Sing his theme song, Wave, or tell jokes!\n• Physically wave, dance, and strike superhero poses in front of your webcam!\n• Enjoy the opening BGM, singing moments, and funny Tamil dialogues!"
			start_level_btn.text = "▶️ START LEVEL 4"

		5:
			entry_next_title.text = "LEVEL 5: LUCKY CHAOS WHEEL 🎡"
			entry_next_subtitle.text = "Carnival Grand Fairground"
			entry_briefing_label.text = "• Step right up to the official giant Lucky Chaos Wheel!\n• Touch the wheel with your hand or click 'SPIN THE WHEEL'!\n• Spin for wild prizes and hilarious interactive challenges!\n• Silly Dance, Funny Face, Hands Up, Penguin Waddle & Wiggle Attack!"
			start_level_btn.text = "▶️ START LEVEL 5"

func _on_start_level_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.load_level(current_lvl + 1)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("chime")
	entry_panel.visible = false
	results_panel.visible = true
	if current_lvl == 3:
		icy_glitter.emitting = true
	elif current_lvl == 4:
		golden_glitter.emitting = true

func _on_replay_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.load_level(current_lvl)

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("chime")
	GameManager.return_to_main_menu()
