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
	
	title_label.text = "%s COMPLETE! 🎉" % GameManager.LEVEL_NAMES.get(current_lvl, "LEVEL").to_upper()
	
	# Configure Level-Specific Results
	match current_lvl:
		1:
			status_label.text = "🌸 Every Little Move Becomes a Magical Memory! ✨"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.92))
			status_label.add_theme_color_override("font_shadow_color", Color(0.85, 0.25, 0.75, 0.85))
			details_label.text = "🌸 Magical Garden Bloomed!\n• Expressions Conquered: Radiant Smiles, Bubbles, Star Bursts\n• Twilight garden & magical wind gusts activated!\n• All 5 facial expressions performed independently!"
			continue_btn.text = "Continue to Level 2 Entry ➔"

		2:
			var fruits_count := GameManager.level2_fruits_sliced
			status_label.text = "🍉 TOTAL TROPICAL FRUITS SLICED: %d! 🏆" % fruits_count
			status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
			status_label.add_theme_color_override("font_shadow_color", Color(0.9, 0.35, 0.1, 0.9))
			details_label.text = "🍉 Tropical Arena Sliced!\n• Total Fruits Sliced: %d 🍉\n• Real Hand Swipes & Fast Blade Combos executed!\n• Playful Firecrackers Triggered: Confetti sparks & celebration!\n• Master of the Blade!" % fruits_count
			continue_btn.text = "Continue to Level 3 Entry ➔"

		3:
			var crystals := GameManager.level3_crystals_collected
			var fish := GameManager.level3_fish_collected
			var total := crystals + fish
			status_label.text = "❄️ TOTAL COLLECTIBLES GATHERED: %d! 💎" % total
			status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
			status_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.5, 0.9, 0.9))
			
			collectibles_row.visible = true
			crystal_count_lbl.text = str(crystals)
			fish_count_lbl.text = str(fish)
			
			# Animate collectible cards with subtle celebratory bouncing tweens
			_animate_collectible_card(crystal_card, 0.0)
			_animate_collectible_card(fish_card, 0.15)
			
			# Continuous gentle icy glitter
			icy_glitter.emitting = true
			
			details_label.text = "🐧 Cute Baby Penguin Hero Guided Safely!\n• Crystals Gathered: %d 💎  |  Icy Fish Caught: %d 🐟\n• Full body motions: Leans, Jumps, Slides & Squats!\n• Baby penguin in blue beanie safely scaled the snowy peaks!" % [crystals, fish]
			continue_btn.text = "Continue to Level 4 Entry ➔"

		4:
			status_label.text = "🎭 SHINCHAN'S STAGE SUPERSTAR! 🔥"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			status_label.add_theme_color_override("font_shadow_color", Color(0.95, 0.2, 0.4, 0.9))
			
			# Continuous golden/rainbow sparkles
			golden_glitter.emitting = true
			
			details_label.text = "🎭 Shinchan's Workshop Stage Rocked!\n• Interactive Chatbot Conversations completed in Tamil & English!\n• Real Movements Mirrored: Waves, Crazy Dance, Hero Pose & Theme Song!\n• Red T-Shirt Shinchan gave a show-stopping performance!"
			continue_btn.text = "Continue to Level 5 Entry ➔"

		5:
			var outcome := GameManager.level5_wheel_outcome
			status_label.text = "🎡 30-SECOND CARNIVAL ROUND CONQUERED! 🏆"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			status_label.add_theme_color_override("font_shadow_color", Color(0.9, 0.25, 0.6, 0.85))
			details_label.text = "🎡 Carnival Prize Wheel Completed in exactly 30 seconds!\n• Wheel Outcome: %s\n• All 5 Realms Genuinely Conquered with real computer-vision tracking!" % outcome
			continue_btn.text = "Acknowledge & Continue 🌟"

	if StickerManager:
		var st_data: Dictionary = StickerManager.get_sticker_data(current_lvl)
		badge_label.text = "🌟 STICKER COLLECTED: %s (Saved to Scrapbook!)" % st_data.get("name", "Sticker")
	else:
		badge_label.text = "🌟 PARTY PERFORMANCE: SPECTACULAR!"
		
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
			entry_next_title.text = "LEVEL 2: FRUIT NINJA 🍉"
			entry_next_subtitle.text = "Neon Tropical Fruit Arena"
			entry_briefing_label.text = "• Wave your hand in front of the camera to slice flying fruit!\n• Slice Watermelons, Bananas, Pineapples & Kiwi for juicy splash combos!\n• Avoid bombs — slicing a bomb triggers a playful firecracker burst!\n• Keep slicing until the session finishes!"
			start_level_btn.text = "▶️ START LEVEL 2"

		3:
			entry_next_title.text = "LEVEL 3: ARCTIC WADDLER (WADDLE WARS) 🐧"
			entry_next_subtitle.text = "Icy Mountain Expedition"
			entry_briefing_label.text = "• Guide our cute baby penguin wearing his blue beanie!\n• Lean your body LEFT or RIGHT to steer along the snowy paths.\n• Raise BOTH HANDS to leap over deep ice crevices.\n• SQUAT DOWN to belly-slide smoothly under frozen crystal arches.\n• Collect shimmering crystals 💎 and fresh icy fish 🐟!"
			start_level_btn.text = "▶️ START LEVEL 3"

		4:
			entry_next_title.text = "LEVEL 4: COPYCAT CHAOS 🎭"
			entry_next_subtitle.text = "Shinchan's Interactive Chatbot Stage"
			entry_briefing_label.text = "• Meet Shinchan in his original red T-shirt on center stage!\n• Interactive Chatbot: Type messages or speak with him in Tamil & English!\n• Ask him to Dance, Sing his theme song, Wave, or tell jokes!\n• Physically wave, dance, and strike superhero poses in front of your webcam!\n• Enjoy the opening BGM, singing moments, and funny Tamil dialogues!"
			start_level_btn.text = "▶️ START LEVEL 4"

		5:
			entry_next_title.text = "LEVEL 5: LUCKY CHAOS WHEEL 🎡"
			entry_next_subtitle.text = "30-Second Carnival Grand Fairground"
			entry_briefing_label.text = "• Step right up to the official giant Lucky Chaos Wheel!\n• Touch the wheel with your hand or click 'SPIN THE WHEEL'!\n• Exactly 30-Second session:\n  - 0–4s: Wheel spin & single outcome selection\n  - 4–19s: 15-second challenge or activity\n  - 19–24s: Reward & result reveal\n  - 24–30s: Grand carnival finale & celebration!"
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
