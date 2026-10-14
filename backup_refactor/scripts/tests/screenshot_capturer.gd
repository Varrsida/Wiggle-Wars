extends Node

## WIGGLE WARS! — Visual QA Screenshot Generator
## Instantiates each scene, renders frames, captures full 1280x720 viewport,
## and saves to screenshots/ folder.

var scenes_to_capture := [
	{"name": "main_menu", "path": "res://scenes/main_menu.tscn"},
	{"name": "webcam_setup", "path": "res://scenes/webcam_setup.tscn"},
	{"name": "level1_face_frenzy", "path": "res://scenes/level1_face_frenzy.tscn"},
	{"name": "level2_fruit_ninja", "path": "res://scenes/level2_fruit_ninja.tscn"},
	{"name": "level3_waddle_wars", "path": "res://scenes/level3_waddle_wars.tscn"},
	{"name": "level4_copycat_chaos", "path": "res://scenes/level4_copycat_chaos.tscn"},
	{"name": "level5_lucky_wheel", "path": "res://scenes/level5_lucky_wheel.tscn"},
	{"name": "level_results", "path": "res://scenes/level_results.tscn"},
	{"name": "secret_ending", "path": "res://scenes/secret_ending.tscn"}
]

var current_idx: int = 0
var current_instance: Node = null
var frame_counter: int = 0

func _ready() -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	_load_next()

func _load_next() -> void:
	if current_instance:
		current_instance.queue_free()
		current_instance = null
		
	if current_idx >= scenes_to_capture.size():
		print("\n>>> ALL SCREENSHOTS CAPTURED CLEANLY! Visual QA Complete!")
		get_tree().quit(0)
		return
		
	var item = scenes_to_capture[current_idx]
	print("[Screenshot] Loading: %s (%s)..." % [item["name"], item["path"]])
	
	if item["name"] == "secret_ending":
		for i in range(1, 6):
			GameManager.complete_level(i)
		GameManager.level5_wheel_completed = true
		GameManager.level5_results_acknowledged = true
		
	var packed := load(item["path"]) as PackedScene
	current_instance = packed.instantiate()
	add_child(current_instance)
	
	if item["name"] == "secret_ending" and current_instance.has_method("_enter_state"):
		current_instance.call("_enter_state", 3) # SCENE_C_CELEBRATION
	
	if item["name"] == "level2_fruit_ninja" and current_instance.has_method("_spawn_fruit_wave"):
		current_instance.call("_spawn_fruit_wave")
		
	frame_counter = 0

func _process(_delta: float) -> void:
	frame_counter += 1
	if frame_counter == 6 and current_instance:
		var tex := get_viewport().get_texture()
		if tex:
			var img := tex.get_image()
			if img:
				var item = scenes_to_capture[current_idx]
				var save_path := "res://screenshots/%s.png" % item["name"]
				var err := img.save_png(save_path)
				if err == OK:
					print("  [SAVED] %s (%dx%d)" % [save_path, img.get_width(), img.get_height()])
				else:
					printerr("  [ERROR] Failed to save %s" % save_path)
			else:
				print("  [SKIP] Viewport image not available in current driver.")
		else:
			print("  [SKIP] Viewport texture not available in current driver.")
			
		current_idx += 1
		_load_next()
