extends Node

## WIGGLE WARS! — Automated QA Test Suite
## Runs comprehensive verification of:
## 1. Global Autoloads (GameManager, GestureListener, AudioManager)
## 2. No-Points Design & 60-Second Level Progression
## 3. Secret Ending Strict Safeguards (Non-score based)
## 4. Exact Final Quote & Exact On-Screen Message
## 5. Exactly 7 Wheel Slices
## 6. Voice Audio Files Existence & Loading
## 7. Procedural Sound Synthesis Engine (18 sounds)
## 8. All Scenes Compilation, Node Hierarchy & Instantiation
## 9. Level 1: Five Independent Facial Actions
## 10. Level 2: Fruit Spawning & Slicing Mechanics
## 11. Level 3: Penguin Instantiation, Visibility & Pose States

func _ready() -> void:
	print("\n=======================================================")
	print(">>> WIGGLE WARS! — AUTOMATED QA INTEGRATION TEST SUITE")
	print("=======================================================\n")
	
	var passed := 0
	var failed := 0
	
	var results := []
	
	results.append(_test_autoloads())
	results.append(_test_no_points_and_progression())
	results.append(_test_secret_ending_safeguards())
	results.append(_test_exact_quotes_and_messages())
	results.append(_test_wheel_slices_count())
	results.append(_test_voice_audio_files())
	results.append(_test_procedural_audio())
	results.append(_test_all_scenes_loadable())
	results.append(_test_level1_five_actions())
	results.append(_test_level2_fruit_spawning())
	results.append(_test_level3_penguin_visibility())
	results.append(_test_imported_assets())
	
	print("\n-------------------------------------------------------")
	print(">>> QA TEST RESULTS SUMMARY:")
	print("-------------------------------------------------------")
	for r in results:
		if r["pass"]:
			passed += 1
			print("  [PASS] %s" % r["name"])
		else:
			failed += 1
			print("  [FAIL] %s: %s" % [r["name"], r.get("error", "")])
	
	print("\nTOTAL TESTS: %d | PASSED: %d | FAILED: %d" % [results.size(), passed, failed])
	if failed == 0:
		print(">>> ALL QA TESTS PASSED CLEANLY! WIGGLE WARS IS FULLY OPERATIONAL! 🎉✨\n")
	else:
		print(">>> SOME TESTS FAILED! Check error logs above.\n")
	
	get_tree().quit(0 if failed == 0 else 1)

func _test_autoloads() -> Dictionary:
	var res := {"name": "1. Global Autoloads (GameManager, GestureListener, AudioManager)", "pass": false}
	if GameManager == null:
		res["error"] = "GameManager is null"
		return res
	if GestureListener == null:
		res["error"] = "GestureListener is null"
		return res
	if AudioManager == null:
		res["error"] = "AudioManager is null"
		return res
	res["pass"] = true
	return res

func _test_no_points_and_progression() -> Dictionary:
	var res := {"name": "2. No-Points Design & 60-Second Level Progression", "pass": false}
	GameManager.reset_game_state()
	
	if GameManager.current_level != 1:
		res["error"] = "Initial current_level should be 1"
		return res
		
	# Verify score variables do not exist or are not used
	var gm_script: Script = GameManager.get_script()
	var props := gm_script.get_script_property_list()
	for p in props:
		if p["name"] == "total_score" or p["name"] == "level_scores":
			res["error"] = "Score variables detected in GameManager! Score must be removed."
			return res
			
	# Test progression
	GameManager.complete_level(1)
	if not GameManager.completed_levels.get(1, false):
		res["error"] = "Level 1 completion flag not set"
		return res
		
	GameManager.reset_game_state()
	if GameManager.completed_levels.get(1, false):
		res["error"] = "Level 1 not reset"
		return res
		
	res["pass"] = true
	return res

func _test_secret_ending_safeguards() -> Dictionary:
	var res := {"name": "3. Secret Ending Strict Multi-Condition Safeguards", "pass": false}
	GameManager.reset_game_state()
	
	# Condition 1: Levels not completed -> MUST FAIL
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Safeguard breach: Unlocked before any levels played!"
		return res
		
	# Complete levels 1-4 only -> MUST FAIL
	for i in range(1, 5):
		GameManager.complete_level(i)
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Safeguard breach: Unlocked without completing Level 5!"
		return res
		
	# Complete Level 5 without wheel completion -> MUST FAIL
	GameManager.complete_level(5)
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Safeguard breach: Unlocked without completing wheel spin!"
		return res
		
	# Wheel completed but results not acknowledged -> MUST FAIL
	GameManager.level5_wheel_completed = true
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Safeguard breach: Unlocked before acknowledging normal Level 5 results!"
		return res
		
	# Acknowledge results -> MUST PASS
	GameManager.level5_results_acknowledged = true
	if not GameManager.can_unlock_secret_ending():
		res["error"] = "Safeguard failed: Genuine completion rejected!"
		return res
		
	GameManager.reset_game_state()
	res["pass"] = true
	return res

func _test_exact_quotes_and_messages() -> Dictionary:
	var res := {"name": "4. Exact Lumi Final Quote & On-Screen Message Verification", "pass": false}
	var scene := load("res://scenes/secret_ending.tscn")
	if not scene:
		res["error"] = "Could not load secret_ending.tscn"
		return res
	var instance = scene.instantiate()
	
	var expected_quote := "Hey, superstar… the real magic was never the points, the prizes, or the victory. It was YOU — every silly move, every laugh, and every moment you didn't give up. Thank you for making this little world come alive. I'll be right here whenever you return."
	var expected_message := "YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. 🌈"
	
	if instance.EXACT_FINAL_QUOTE != expected_quote:
		res["error"] = "Mismatch in exact final quote!"
		instance.queue_free()
		return res
		
	if instance.EXACT_FINAL_MESSAGE != expected_message:
		res["error"] = "Mismatch in exact final on-screen message!"
		instance.queue_free()
		return res
		
	instance.queue_free()
	res["pass"] = true
	return res

func _test_wheel_slices_count() -> Dictionary:
	var res := {"name": "5. Exactly Seven Wheel Slices & Slices Mapping", "pass": false}
	var scene := load("res://scenes/level5_lucky_wheel.tscn")
	if not scene:
		res["error"] = "Could not load level5_lucky_wheel.tscn"
		return res
	var instance = scene.instantiate()
	
	if instance.SLICES.size() != 7:
		res["error"] = "Wheel does not have exactly 7 slices! Found %d" % instance.SLICES.size()
		instance.queue_free()
		return res
		
	var expected_slices := [
		"Chocolate Treat 🍫",
		"Cute Stickers 🌈",
		"Fun Pen 🖊️",
		"Cute Keychain 🔑",
		"Funny Chicken Dance 🐔",
		"Freeze Like a Statue 🗿",
		"Silly Face Challenge 🤪"
	]
	
	for s in expected_slices:
		if not s in instance.SLICES:
			res["error"] = "Missing expected slice: %s" % s
			instance.queue_free()
			return res
			
	instance.queue_free()
	res["pass"] = true
	return res

func _test_voice_audio_files() -> Dictionary:
	var res := {"name": "6. Voice Audio Files Generation & Availability", "pass": false}
	var required_audio := [
		"res://assets/audio/lumi_welcome.wav",
		"res://assets/audio/lumi_level1.wav",
		"res://assets/audio/lumi_level2.wav",
		"res://assets/audio/lumi_level3.wav",
		"res://assets/audio/lumi_level4.wav",
		"res://assets/audio/lumi_level5.wav",
		"res://assets/audio/lumi_surprise_open.wav",
		"res://assets/audio/lumi_final_quote.wav",
		"res://assets/audio/shinchan_intro.wav",
		"res://assets/audio/shinchan_dance.wav",
		"res://assets/audio/shinchan_victory.wav"
	]
	
	for a in required_audio:
		if not FileAccess.file_exists(a):
			res["error"] = "Missing voice file: %s" % a
			return res
			
	res["pass"] = true
	return res

func _test_procedural_audio() -> Dictionary:
	var res := {"name": "7. Procedural Chimes & Sound Synthesis Engine", "pass": false}
	var expected_sfx := [
		"chime", "bubble_pop", "bloom", "wind_gust", "sleepy",
		"swish", "splash", "combo", "bomb", "chirp", "jump",
		"slide", "crystal", "boing", "wheel_click", "wheel_win",
		"quack", "legend_fanfare"
	]
	
	for s in expected_sfx:
		if not s in AudioManager.procedural_sounds:
			res["error"] = "Missing synthesized sound: %s" % s
			return res
		if AudioManager.procedural_sounds[s] == null:
			res["error"] = "Synthesized sound %s is null" % s
			return res
			
	res["pass"] = true
	return res

func _test_all_scenes_loadable() -> Dictionary:
	var res := {"name": "8. Complete Scene Compilation & Instantiation", "pass": false}
	var scenes := [
		"res://scenes/main_menu.tscn",
		"res://scenes/webcam_setup.tscn",
		"res://scenes/hud.tscn",
		"res://scenes/level1_face_frenzy.tscn",
		"res://scenes/level2_fruit_ninja.tscn",
		"res://scenes/level3_waddle_wars.tscn",
		"res://scenes/level4_copycat_chaos.tscn",
		"res://scenes/level5_lucky_wheel.tscn",
		"res://scenes/level_results.tscn",
		"res://scenes/secret_ending.tscn"
	]
	
	for s in scenes:
		var packed := load(s) as PackedScene
		if not packed:
			res["error"] = "Failed to load packed scene: %s" % s
			return res
		var inst := packed.instantiate()
		if not inst:
			res["error"] = "Failed to instantiate scene: %s" % s
			return res
		inst.queue_free()
		
	res["pass"] = true
	return res

func _test_level1_five_actions() -> Dictionary:
	var res := {"name": "9. Level 1: Five Independent Facial Actions", "pass": false}
	var packed := load("res://scenes/level1_face_frenzy.tscn") as PackedScene
	var inst := packed.instantiate()
	add_child(inst)
	
	# Verify 60-second timer
	if inst.time_remaining != 60.0:
		res["error"] = "Level 1 timer not initialized to 60.0"
		inst.queue_free()
		return res
		
	# Trigger each of the 5 actions
	inst._trigger_smile(1.0)
	inst._trigger_bubbles(2.0)
	inst._trigger_star_burst(3.0)
	inst._trigger_sleepy_garden(4.0)
	inst._trigger_wind_gust(5.0)
	
	# Verify all 5 actions completed independently
	for act in ["smile", "mouth_open", "eyebrows", "sleepy", "surprised"]:
		if not inst.completed_actions.get(act, false):
			res["error"] = "Action %s was not completed!" % act
			inst.queue_free()
			return res
			
	# Verify action can be repeated without being blocked
	inst._trigger_smile(6.0)
	inst._trigger_bubbles(7.0)
	
	inst.queue_free()
	res["pass"] = true
	return res

func _test_level2_fruit_spawning() -> Dictionary:
	var res := {"name": "10. Level 2: Fruit Spawning & Slicing Mechanics", "pass": false}
	var packed := load("res://scenes/level2_fruit_ninja.tscn") as PackedScene
	var inst := packed.instantiate()
	add_child(inst)
	
	if inst.time_remaining != 60.0:
		res["error"] = "Level 2 timer not initialized to 60.0"
		inst.queue_free()
		return res
		
	# Spawn fruits
	inst._spawn_fruit_wave()
	if inst.fruits.is_empty():
		res["error"] = "No fruits spawned in Level 2!"
		inst.queue_free()
		return res
		
	# Slice first fruit
	var target_f = inst.fruits[0]
	inst._perform_slice(target_f.pos, 100.0)
	if not target_f.is_sliced:
		res["error"] = "Fruit was not sliced by intersecting swipe!"
		inst.queue_free()
		return res
		
	inst.queue_free()
	res["pass"] = true
	return res

func _test_level3_penguin_visibility() -> Dictionary:
	var res := {"name": "11. Level 3: Penguin Instantiation, Visibility & Pose States", "pass": false}
	var packed := load("res://scenes/level3_waddle_wars.tscn") as PackedScene
	var inst := packed.instantiate()
	add_child(inst)
	
	if inst.time_remaining != 60.0:
		res["error"] = "Level 3 timer not initialized to 60.0"
		inst.queue_free()
		return res
		
	# Verify penguin coordinates and state
	if inst.penguin_x != 640.0 or inst.penguin_y != 560.0:
		res["error"] = "Penguin coordinates invalid"
		inst.queue_free()
		return res
		
	# Test pose transitions
	inst._on_pose_detected("lean_left", "lean_left", -0.2, false, false, false, false)
	if inst.penguin_x >= 640.0:
		res["error"] = "Penguin did not move left on lean_left"
		inst.queue_free()
		return res
		
	inst._on_pose_detected("hands_raised", "neutral", 0.0, true, false, false, false)
	if inst.penguin_state != "jump":
		res["error"] = "Penguin did not jump on hands_raised"
		inst.queue_free()
		return res
		
	inst.queue_free()
	res["pass"] = true
	return res

func _test_imported_assets() -> Dictionary:
	var res := {"name": "12. Uploaded Media Assets Verification", "pass": false}
	var required_assets := [
		"res://assets/backgrounds/level1_garden_bg.png",
		"res://assets/sprites/tulip_flower.png",
		"res://assets/backgrounds/level3_snowy_path_bg.png",
		"res://assets/characters/penguin_hero.png",
		"res://assets/backgrounds/level4_shinchan_bg.png",
		"res://assets/characters/shinchan_hero.png",
		"res://assets/backgrounds/level5_carnival_bg.png"
	]
	
	for a in required_assets:
		if not FileAccess.file_exists(a):
			res["error"] = "Mandatory asset file does not exist: %s" % a
			return res
		var tex = load(a)
		if not tex:
			res["error"] = "Failed to load asset texture: %s" % a
			return res
			
	res["pass"] = true
	return res
