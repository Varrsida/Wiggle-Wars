extends Node

## WIGGLE WARS! — Global Persistent Sticker Manager
## Manages sticker unlocking, persistent save/load via user://stickers.json,
## and progress tracking across all 5 levels for the Scrapbook album.

signal sticker_unlocked(level_num: int, sticker_info: Dictionary)

const SAVE_PATH := "user://stickers.json"

var stickers: Dictionary = {
	1: {
		"id": 1,
		"name": "Radiant Bloom 🌸",
		"level": "Level 1: Face Frenzy",
		"desc": "Awarded for discovering radiant smiles and blooming garden flowers!",
		"icon": "res://assets/sprites/sticker_level1.png",
		"unlocked": false,
		"unlocked_at": ""
	},
	2: {
		"id": 2,
		"name": "Juicy Slicer 🍉",
		"level": "Level 2: Fruit Ninja",
		"desc": "Awarded for lightning hand reflexes and tropical fruit cutting!",
		"icon": "res://assets/sprites/sticker_level2.png",
		"unlocked": false,
		"unlocked_at": ""
	},
	3: {
		"id": 3,
		"name": "Arctic Waddler 🐧",
		"level": "Level 3: Waddle Wars",
		"desc": "Awarded for guiding the adorable baby penguin across icy mountains!",
		"icon": "res://assets/sprites/sticker_level3.png",
		"unlocked": false,
		"unlocked_at": ""
	},
	4: {
		"id": 4,
		"name": "Stage Star 🎭",
		"level": "Level 4: Copycat Chaos",
		"desc": "Awarded for dancing, posing, and matching Shinchan on stage!",
		"icon": "res://assets/sprites/sticker_level4.png",
		"unlocked": false,
		"unlocked_at": ""
	},
	5: {
		"id": 5,
		"name": "Chaos Champion 🎡",
		"level": "Level 5: Lucky Chaos Wheel",
		"desc": "Awarded for braving the lucky wheel and conquering hilarious challenges!",
		"icon": "res://assets/sprites/sticker_level5.png",
		"unlocked": false,
		"unlocked_at": ""
	},
	6: {
		"id": 6,
		"name": "Wonderland Gateway 🌈",
		"level": "Surprise Wonderland",
		"desc": "Awarded for discovering the secret golden gateway with Lumi and the Angel!",
		"icon": "res://assets/sprites/memory_card_6.png",
		"unlocked": false,
		"unlocked_at": ""
	},
	7: {
		"id": 7,
		"name": "Wiggle Wars Legend 🏆",
		"level": "Master Realm",
		"desc": "Awarded for conquering all five realms and unlocking the legendary secret ending!",
		"icon": "res://assets/sprites/memory_card_7.png",
		"unlocked": false,
		"unlocked_at": ""
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_stickers()

func award_sticker(level_num: int) -> bool:
	if not stickers.has(level_num):
		return false
	
	var st: Dictionary = stickers[level_num]
	if not st.get("unlocked", false):
		st["unlocked"] = true
		st["unlocked_at"] = Time.get_datetime_string_from_system()
		save_stickers()
		sticker_unlocked.emit(level_num, st)
		print("[StickerManager] Sticker unlocked for Level %d: %s" % [level_num, st["name"]])
		return true
	return false

func is_sticker_unlocked(level_num: int) -> bool:
	return stickers.get(level_num, {}).get("unlocked", false)

func get_sticker_data(level_num: int) -> Dictionary:
	return stickers.get(level_num, {})

func get_unlocked_count() -> int:
	var count := 0
	for k in stickers:
		if stickers[k].get("unlocked", false):
			count += 1
	return count

func are_all_stickers_unlocked() -> bool:
	return get_unlocked_count() == stickers.size()

func save_stickers() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		printerr("[StickerManager] Could not open save file for writing: %s" % SAVE_PATH)
		return
	
	var data: Dictionary = {}
	for k in stickers:
		data[str(k)] = {
			"unlocked": stickers[k]["unlocked"],
			"unlocked_at": stickers[k]["unlocked_at"]
		}
	
	var json_str := JSON.stringify(data, "\t")
	file.store_string(json_str)
	file.close()
	print("[StickerManager] Stickers saved successfully to %s" % SAVE_PATH)

func load_stickers() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
		
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK or not json.data is Dictionary:
		return
		
	var data: Dictionary = json.data
	for k_str in data:
		var lvl := int(k_str)
		if stickers.has(lvl) and data[k_str] is Dictionary:
			stickers[lvl]["unlocked"] = data[k_str].get("unlocked", false)
			stickers[lvl]["unlocked_at"] = data[k_str].get("unlocked_at", "")
	
	print("[StickerManager] Stickers loaded: %d / %d unlocked." % [get_unlocked_count(), stickers.size()])

func reset_stickers() -> void:
	for k in stickers:
		stickers[k]["unlocked"] = false
		stickers[k]["unlocked_at"] = ""
	save_stickers()
	print("[StickerManager] All stickers reset.")
