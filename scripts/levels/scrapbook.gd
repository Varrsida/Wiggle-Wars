extends Control

## WIGGLE WARS! — Sticker Scrapbook & Memory Album 📖✨
## Displays the authentic supplied scrapbook artwork with exactly two clean UI elements:
## 1. WIGGLE WARS! MEMORY SCRAPBOOK
## 2. BACK TO MAIN

@onready var title_label: Label = $TitleLabel
@onready var back_btn: Button = $BackBtn

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	AudioManager.play_sfx("chime")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("boing")
	GameManager.return_to_main_menu()
