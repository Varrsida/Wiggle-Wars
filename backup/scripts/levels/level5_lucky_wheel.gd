extends Node2D

## WIGGLE WARS! — Level 5: Lucky Chaos Wheel 🎡
## The Carnival of Unexpected Prizes
## Features EXACTLY SEVEN wheel slices:
## 1. Chocolate Prize 🍫
## 2. Legendary Pen ✨
## 3. Sticker Jackpot 🌈
## 4. Mystery Keychain 🔑
## 5. Mirror Twin 🪞 (5 seconds reverse-imitation challenge)
## 6. Duck Apocalypse 🦆 (5-7 seconds giant duck on head & duck chase)
## 7. Chicken Dance Challenge 🐔 (5 seconds chicken dance challenge)

@onready var hud: CanvasLayer = $HUD
@onready var wheel_node: Node2D = $CarnivalStage/Wheel
@onready var spin_btn: Button = $CarnivalStage/SpinBtn
@onready var event_overlay: CanvasLayer = $EventOverlay
@onready var event_title: Label = $EventOverlay/Panel/VBox/EventTitle
@onready var event_desc: Label = $EventOverlay/Panel/VBox/EventDesc
@onready var ducks_container: Node2D = $DucksContainer

const SLICES: Array[String] = [
	"Chocolate Prize 🍫",
	"Legendary Pen ✨",
	"Sticker Jackpot 🌈",
	"Mystery Keychain 🔑",
	"Mirror Twin 🪞",
	"Duck Apocalypse 🦆",
	"Chicken Dance Challenge 🐔"
]

const SLICE_COLORS: Array[Color] = [
	Color(0.85, 0.35, 0.2), # Chocolate / Brown-Red
	Color(0.2, 0.75, 0.95), # Cyan / Pen
	Color(0.95, 0.45, 0.85),# Pink / Stickers
	Color(1.0, 0.8, 0.2),  # Gold / Keychain
	Color(0.4, 0.45, 0.95), # Purple-Blue / Mirror Twin
	Color(0.95, 0.85, 0.1), # Yellow / Duck Apocalypse
	Color(0.95, 0.3, 0.3)   # Red / Chicken Dance
]

var wheel_angle: float = 0.0
var wheel_speed: float = 0.0
var is_spinning: bool = false
var target_slice_idx: int = -1
var target_angle: float = 0.0
var spin_progress: float = 0.0

var active_challenge: String = ""
var challenge_timer: float = 0.0
var level_finished: bool = false
var time_elapsed: float = 0.0

func _ready() -> void:
	hud.setup_hud("Level 5: Lucky Chaos Wheel 🎡", "Press 'SPIN THE WHEEL' to test your carnival luck!")
	event_overlay.visible = false
	
	AudioManager.play_voice_file("res://assets/audio/lumi_level5.wav",
		"Step right up to the Lucky Chaos Wheel! Spin for wild prizes and hilarious surprises!", 6.0)

	GestureListener.pose_detected.connect(_on_pose_detected)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	if is_spinning:
		_process_wheel_spin(delta)
	
	if active_challenge != "":
		_process_challenge(delta)
		
	queue_redraw()

func _on_spin_btn_pressed() -> void:
	if is_spinning or active_challenge != "" or level_finished:
		return
	
	spin_btn.disabled = true
	# Pick random outcome among exactly 7 slices
	target_slice_idx = randi() % 7
	GameManager.level5_wheel_outcome = SLICES[target_slice_idx]
	
	# Exactly 7 slices: each slice is TAU / 7 (~51.43 degrees)
	# Top pointer is at -PI / 2 (270 deg)
	var slice_arc := TAU / 7.0
	# Angle where slice center lands under top pointer
	var slice_center := target_slice_idx * slice_arc + (slice_arc * 0.5)
	# Target total rotations (e.g. 5 full spins + slice offset)
	var pointer_offset := 3.0 * PI / 2.0
	target_angle = (TAU * 5.0) + (pointer_offset - slice_center)
	
	wheel_speed = 18.0
	spin_progress = 0.0
	is_spinning = true
	AudioManager.play_sfx("wheel_click")
	hud.set_instruction("Wheel is spinning... What will you win?")

func _process_wheel_spin(delta: float) -> void:
	spin_progress += delta * 0.25 # lasts ~4 seconds
	if spin_progress < 1.0:
		# Smooth deceleration cubic ease out
		var t := 1.0 - pow(1.0 - spin_progress, 3.0)
		wheel_angle = lerpf(0.0, target_angle, t)
		if fmod(wheel_angle, TAU / 7.0) < 0.2:
			AudioManager.play_sfx("wheel_click")
	else:
		wheel_angle = target_angle
		is_spinning = false
		_on_wheel_stopped()

func _on_wheel_stopped() -> void:
	AudioManager.play_sfx("wheel_win")
	hud.set_instruction("Result: %s!" % SLICES[target_slice_idx])
	
	# Execute the selected outcome
	match target_slice_idx:
		0:
			_outcome_chocolate()
		1:
			_outcome_legendary_pen()
		2:
			_outcome_sticker_jackpot()
		3:
			_outcome_mystery_keychain()
		4:
			_outcome_mirror_twin()
		5:
			_outcome_duck_apocalypse()
		6:
			_outcome_chicken_dance()

# ------------------------------------------------------------------------------
# 7 SPECIFIED WHEEL OUTCOMES
# ------------------------------------------------------------------------------
func _outcome_chocolate() -> void:
	GameManager.add_score(20)
	_show_event_modal("CHOCOLATE PRIZE 🍫", "Delicious digital chocolate bars floating all around! Sweet victory!")
	_finish_event_after(3.0)

func _outcome_legendary_pen() -> void:
	GameManager.add_score(25)
	_show_event_modal("LEGENDARY PEN ✨", "You unlocked the Mythic Golden Pen! Writes your name into legend!")
	_finish_event_after(3.0)

func _outcome_sticker_jackpot() -> void:
	GameManager.add_score(30)
	_show_event_modal("STICKER JACKPOT 🌈", "Super colorful sticker explosion! Confetti and sparkle shower!")
	_finish_event_after(3.0)

func _outcome_mystery_keychain() -> void:
	GameManager.add_score(20)
	_show_event_modal("MYSTERY KEYCHAIN 🔑", "A shiny glowing lucky charm keychain awarded for your achievements!")
	_finish_event_after(3.0)

func _outcome_mirror_twin() -> void:
	active_challenge = "mirror_twin"
	challenge_timer = 5.0
	_show_event_modal("MIRROR TWIN CHALLENGE 🪞", "Reverse Imitation! When target says LEAN LEFT, lean RIGHT! (5 Seconds)")

func _outcome_duck_apocalypse() -> void:
	active_challenge = "duck_apocalypse"
	challenge_timer = 6.0
	AudioManager.play_sfx("quack")
	_show_event_modal("DUCK APOCALYPSE 🦆", "QUACK! A GIANT DUCK HAS LANDED ON YOUR HEAD! Ducks everywhere!")
	_spawn_ducks()

func _outcome_chicken_dance() -> void:
	active_challenge = "chicken_dance"
	challenge_timer = 5.0
	_show_event_modal("CHICKEN DANCE CHALLENGE 🐔", "Flap your elbows rhythmically like a funny chicken! (5 Seconds)")

func _show_event_modal(t: String, d: String) -> void:
	event_title.text = t
	event_desc.text = d
	event_overlay.visible = true

func _spawn_ducks() -> void:
	for i in range(12):
		var duck := Node2D.new()
		duck.position = Vector2(randf_range(100, 1180), randf_range(300, 650))
		ducks_container.add_child(duck)
		
		var tw := create_tween().set_loops(4)
		tw.tween_property(duck, "position:x", duck.position.x + randf_range(-150, 150), 1.2)
		tw.tween_callback(func(): AudioManager.play_sfx("quack"))

func _process_challenge(delta: float) -> void:
	challenge_timer -= delta
	event_desc.text = "Time Remaining: %.1f seconds!" % maxf(0.0, challenge_timer)
	
	if challenge_timer <= 0.0:
		var challenge_done := active_challenge
		active_challenge = ""
		GameManager.add_score(25)
		AudioManager.play_sfx("combo")
		event_title.text = "CHALLENGE PASSED! 🎉"
		event_desc.text = "Great moves! +25 Points awarded!"
		_finish_event_after(2.0)

func _on_pose_detected(gest: String, _lean: String, _amt: float, _hr: bool, _ae: bool, _sq: bool, cd: bool) -> void:
	if active_challenge == "chicken_dance" and (cd or gest == "chicken_dance"):
		AudioManager.play_sfx("quack")
		hud.set_instruction("🐔 Chicken dance motion recognized! Flapping on beat!")

func _finish_event_after(sec: float) -> void:
	var tw := create_tween()
	tw.tween_interval(sec)
	tw.tween_callback(func():
		event_overlay.visible = false
		_show_normal_level5_results()
	)

func _show_normal_level5_results() -> void:
	# Normal Level 5 results must finish BEFORE secret ending can unlock!
	GameManager.level5_wheel_completed = true
	GameManager.complete_level(5)
	get_tree().change_scene_to_file("res://scenes/level_results.tscn")

func _draw() -> void:
	var center := Vector2(640.0, 360.0)
	var radius := 220.0
	var slice_arc := TAU / 7.0
	
	# Draw Exactly 7 Slices
	for i in range(7):
		var start_a := wheel_angle + (i * slice_arc)
		var end_a := start_a + slice_arc
		var pts := PackedVector2Array([center])
		for step in range(16):
			var a := lerpf(start_a, end_a, float(step) / 15.0)
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		draw_polygon(pts, PackedColorArray([SLICE_COLORS[i]]))
		# Slice border
		draw_line(center, center + Vector2(cos(start_a), sin(start_a)) * radius, Color.WHITE, 2.0)

	# Wheel Rim
	draw_arc(center, radius, 0.0, TAU, 64, Color(1.0, 0.85, 0.2), 12.0)
	draw_circle(center, 28.0, Color(0.15, 0.18, 0.3))
	draw_circle(center, 12.0, Color.WHITE)

	# Top Pointer Indicator
	var pointer_top := center + Vector2(0, -radius - 10.0)
	draw_polygon(PackedVector2Array([
		pointer_top + Vector2(0, 35),
		pointer_top + Vector2(-16, -10),
		pointer_top + Vector2(16, -10)
	]), PackedColorArray([Color(1.0, 0.2, 0.2)]))
	draw_circle(pointer_top + Vector2(0, -10), 10.0, Color.GOLD)

	# Duck Apocalypse overlay ducks
	if active_challenge == "duck_apocalypse":
		# Giant Duck on head at bottom center
		var giant_duck_pos := Vector2(640.0, 200.0)
		draw_circle(giant_duck_pos, 60.0, Color(1.0, 0.88, 0.1)) # Body
		draw_circle(giant_duck_pos + Vector2(30, -35), 35.0, Color(1.0, 0.88, 0.1)) # Head
		draw_circle(giant_duck_pos + Vector2(40, -42), 6.0, Color.BLACK) # Eye
		draw_polygon(PackedVector2Array([
			giant_duck_pos + Vector2(60, -35), giant_duck_pos + Vector2(85, -30), giant_duck_pos + Vector2(60, -25)
		]), PackedColorArray([Color(1.0, 0.5, 0.1)])) # Orange Bill
