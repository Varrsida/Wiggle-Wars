extends Node

## WIGGLE WARS! — Automated QA Test Suite
## Runs comprehensive verification of all 5 levels, gestures, audio, speech,
## exactly 7 wheel slices, secret ending safeguards, exact quotes, and game flow.

func _ready() -> void:
	print("\n=======================================================")
	print(">>> WIGGLE WARS! — AUTOMATED QA INTEGRATION TEST SUITE")
	print("=======================================================\n")
	
	var passed := 0
	var failed := 0
	
	var results := []
	
	# Test 1: Autoload verification
	var t1 = _test_autoloads()
	results.append(t1)
	
	# Test 2: Scoring & progression
	var t2 = _test_scoring_and_progression()
	results.append(t2)
	
	# Test 3: Secret ending strict safeguards
	var t3 = _test_secret_ending_safeguards()
	results.append(t3)
	
	# Test 4: Exact quotes and messages verification
	var t4 = _test_exact_quotes_and_messages()
	results.append(t4)
	
	# Test 5: Exactly seven wheel slices
	var t5 = _test_wheel_slices_count()
	results.append(t5)
	
	# Test 6: Voice audio files existence
	var t6 = _test_voice_audio_files()
	results.append(t6)
	
	# Test 7: Procedural audio synthesis
	var t7 = _test_procedural_audio()
	results.append(t7)
	
	# Test 8: Scene file loading verification
	var t8 = _test_all_scenes_loadable()
	results.append(t8)
	
	# Summary
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

func _test_scoring_and_progression() -> Dictionary:
	var res := {"name": "2. Scoring, Level Completion & Replay State", "pass": false}
	GameManager.reset_game_state()
	
	if GameManager.total_score != 0 or GameManager.current_level != 1:
		res["error"] = "Initial state invalid"
		return res
		
	GameManager.add_score(10)
	GameManager.add_score(15)
	if GameManager.total_score != 25 or GameManager.level_scores[1] != 25:
		res["error"] = "Score addition calculation incorrect"
		return res
		
	GameManager.complete_level(1)
	if not GameManager.completed_levels[1]:
		res["error"] = "Level 1 completion flag not set"
		return res
		
	res["pass"] = true
	return res

func _test_secret_ending_safeguards() -> Dictionary:
	var res := {"name": "3. Secret Ending Strict Multi-Condition Safeguards", "pass": false}
	GameManager.reset_game_state()
	
	# 1. Unlocked initially? MUST BE FALSE
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Secret ending unlocked initially without completing levels!"
		return res
		
	# 2. Only levels 1-4 completed? MUST BE FALSE
	for i in range(1, 5):
		GameManager.completed_levels[i] = true
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Secret ending unlocked before completing level 5!"
		return res
		
	# 3. Level 5 completed but wheel not completed? MUST BE FALSE
	GameManager.completed_levels[5] = true
	GameManager.level5_wheel_completed = false
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Secret ending unlocked before wheel finished!"
		return res
		
	# 4. Wheel completed but normal results not acknowledged? MUST BE FALSE
	GameManager.level5_wheel_completed = true
	GameManager.level5_results_acknowledged = false
	if GameManager.can_unlock_secret_ending():
		res["error"] = "Secret ending unlocked before normal Level 5 results acknowledged!"
		return res
		
	# 5. All 5 completed + wheel done + normal results acknowledged? MUST BE TRUE!
	GameManager.level5_results_acknowledged = true
	if not GameManager.can_unlock_secret_ending():
		res["error"] = "Secret ending failed to unlock when all conditions genuinely met!"
		return res
		
	res["pass"] = true
	return res

func _test_exact_quotes_and_messages() -> Dictionary:
	var res := {"name": "4. Exact Lumi Final Quote & On-Screen Message Verification", "pass": false}
	
	var expected_quote := "Hey, superstar… the real magic was never the points, the prizes, or the victory. It was YOU — every silly move, every laugh, and every moment you didn't give up. Thank you for making this little world come alive. I'll be right here whenever you return."
	var expected_msg := "YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. 🌈"
	
	var ending_script := load("res://scripts/levels/secret_ending.gd")
	if not ending_script:
		res["error"] = "Could not load secret_ending.gd"
		return res
		
	var ending_inst = ending_script.new()
	var quote_val = ending_inst.get("EXACT_FINAL_QUOTE")
	var msg_val = ending_inst.get("EXACT_FINAL_MESSAGE")
	ending_inst.free()
	
	if quote_val != expected_quote:
		res["error"] = "EXACT_FINAL_QUOTE mismatch! Expected '%s', got '%s'" % [expected_quote, str(quote_val)]
		return res
		
	if msg_val != expected_msg:
		res["error"] = "EXACT_FINAL_MESSAGE mismatch! Expected '%s', got '%s'" % [expected_msg, str(msg_val)]
		return res
		
	res["pass"] = true
	return res

func _test_wheel_slices_count() -> Dictionary:
	var res := {"name": "5. Exactly Seven Wheel Slices & Slices Mapping", "pass": false}
	var wheel_script := load("res://scripts/levels/level5_lucky_wheel.gd")
	if not wheel_script:
		res["error"] = "Could not load level5_lucky_wheel.gd"
		return res
		
	var wheel_inst = wheel_script.new()
	var slices = wheel_inst.get("SLICES")
	wheel_inst.free()
	
	if not (slices is Array) or slices.size() != 7:
		res["error"] = "Wheel does not contain exactly 7 slices! Found: %s" % (str(slices.size()) if slices is Array else "not array")
		return res
		
	var expected_slices := [
		"Chocolate Prize 🍫",
		"Legendary Pen ✨",
		"Sticker Jackpot 🌈",
		"Mystery Keychain 🔑",
		"Mirror Twin 🪞",
		"Duck Apocalypse 🦆",
		"Chicken Dance Challenge 🐔"
	]
	
	for s in expected_slices:
		if not s in slices:
			res["error"] = "Required slice '%s' missing from wheel!" % s
			return res
			
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
		"res://assets/audio/shinchan_wave.wav",
		"res://assets/audio/shinchan_pose.wav",
		"res://assets/audio/shinchan_victory.wav"
	]
	
	for a in required_audio:
		if not FileAccess.file_exists(a):
			res["error"] = "Required audio file missing: %s" % a
			return res
			
	res["pass"] = true
	return res

func _test_procedural_audio() -> Dictionary:
	var res := {"name": "7. Procedural Chimes & Sound Synthesis Engine", "pass": false}
	var required_sfx := [
		"chime", "bubble_pop", "bloom", "wind_gust", "sleepy",
		"swish", "splash", "combo", "bomb",
		"chirp", "jump", "slide", "crystal",
		"boing", "wheel_click", "wheel_win", "quack", "legend_fanfare"
	]
	
	for s in required_sfx:
		if not s in AudioManager.procedural_sounds:
			res["error"] = "Procedural SFX '%s' not registered!" % s
			return res
		var stream: AudioStream = AudioManager.procedural_sounds[s]
		if stream == null or not (stream is AudioStreamWAV):
			res["error"] = "Procedural SFX '%s' stream is invalid" % s
			return res
			
	res["pass"] = true
	return res

func _test_all_scenes_loadable() -> Dictionary:
	var res := {"name": "8. Complete Scene Compilation & Instantiation", "pass": false}
	var scenes_to_test := [
		"res://scenes/main_menu.tscn",
		"res://scenes/webcam_setup.tscn",
		"res://scenes/hud.tscn",
		"res://scenes/level_results.tscn",
		"res://scenes/level1_face_frenzy.tscn",
		"res://scenes/level2_fruit_ninja.tscn",
		"res://scenes/level3_waddle_wars.tscn",
		"res://scenes/level4_copycat_chaos.tscn",
		"res://scenes/level5_lucky_wheel.tscn",
		"res://scenes/secret_ending.tscn"
	]
	
	for sc_path in scenes_to_test:
		var packed := load(sc_path) as PackedScene
		if not packed:
			res["error"] = "Failed to load scene: %s" % sc_path
			return res
		var inst = packed.instantiate()
		if not inst:
			res["error"] = "Failed to instantiate scene: %s" % sc_path
			return res
		inst.free()
		
	res["pass"] = true
	return res
