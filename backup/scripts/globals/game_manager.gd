extends Node

## WIGGLE WARS! — Global Game Manager
## Manages game state, scoring, progression, timers, and safeguards for the secret ending.

signal score_changed(new_score: int, added: int)
signal level_completed(level_num: int, score: int)
signal game_reset()

var current_level: int = 1
var total_score: int = 0
var level_scores: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
var completed_levels: Dictionary = {1: false, 2: false, 3: false, 4: false, 5: false}

var level5_wheel_outcome: String = ""
var level5_wheel_completed: bool = false
var level5_results_acknowledged: bool = false
var secret_ending_unlocked: bool = false

var is_paused: bool = false
var level_start_time: float = 0.0

const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/level1_face_frenzy.tscn",
	2: "res://scenes/level2_fruit_ninja.tscn",
	3: "res://scenes/level3_waddle_wars.tscn",
	4: "res://scenes/level4_copycat_chaos.tscn",
	5: "res://scenes/level5_lucky_wheel.tscn"
}

const LEVEL_NAMES: Dictionary = {
	1: "Level 1: Face Frenzy 🌸",
	2: "Level 2: Fruit Ninja 🍉",
	3: "Level 3: Waddle Wars 🐧",
	4: "Level 4: Copycat Chaos 🎭",
	5: "Level 5: Lucky Chaos Wheel 🎡"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_score(amount: int) -> void:
	if amount <= 0:
		return
	total_score += amount
	level_scores[current_level] = level_scores.get(current_level, 0) + amount
	score_changed.emit(total_score, amount)
	print("[GameManager] Score +%d | Total: %d | Level %d: %d" % [amount, total_score, current_level, level_scores[current_level]])

func complete_level(level_num: int) -> void:
	completed_levels[level_num] = true
	var l_score: int = level_scores.get(level_num, 0)
	level_completed.emit(level_num, l_score)
	print("[GameManager] Level %d completed with score %d!" % [level_num, l_score])

func can_unlock_secret_ending() -> bool:
	# STRICT SAFEGUARD: All 5 levels must be completed AND Level 5 wheel finished AND results acknowledged!
	for i in range(1, 6):
		if not completed_levels.get(i, false):
			return false
	if not level5_wheel_completed:
		return false
	if not level5_results_acknowledged:
		return false
	return true

func reset_game_state() -> void:
	current_level = 1
	total_score = 0
	level_scores = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	completed_levels = {1: false, 2: false, 3: false, 4: false, 5: false}
	level5_wheel_outcome = ""
	level5_wheel_completed = false
	level5_results_acknowledged = false
	secret_ending_unlocked = false
	is_paused = false
	game_reset.emit()
	print("[GameManager] Full game state reset.")

func start_game() -> void:
	reset_game_state()
	load_level(1)

func load_level(level_num: int) -> void:
	if level_num in LEVEL_SCENES:
		current_level = level_num
		level_start_time = Time.get_ticks_msec() / 1000.0
		get_tree().change_scene_to_file(LEVEL_SCENES[level_num])
		print("[GameManager] Transitioning to %s" % LEVEL_NAMES.get(level_num, "Unknown"))

func load_secret_ending() -> void:
	if can_unlock_secret_ending():
		secret_ending_unlocked = true
		get_tree().change_scene_to_file("res://scenes/secret_ending.tscn")
		print("[GameManager] Opening Surprise Wonderland! Secret ending unlocked!")
	else:
		printerr("[GameManager] Attempted to open secret ending prematurely! Safeguard blocked transition.")

func return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
