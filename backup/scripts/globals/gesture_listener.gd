extends Node

## WIGGLE WARS! — Multi-Modal Gesture & Video Listener
## Manages TCP 9999 JSON-lines telemetry, TCP 9998 webcam video stream,
## bi-directional tracker communication, and testing fallbacks.

signal tracker_connected()
signal tracker_disconnected()
signal face_detected(expression: String, scores: Dictionary, eye_closed_sec: float)
signal hand_detected(cursor_pos: Vector2, swipe: String, is_waving: bool, wave_speed: float, reach_up: bool, is_open: bool, is_fist: bool)
signal pose_detected(gesture: String, lean: String, lean_amount: float, hands_raised: bool, arms_extended: bool, squatting: bool, chicken_dance: bool)
signal telemetry_updated(telemetry: Dictionary)
signal speech_result(success: bool, text: String, audio_file: String)
signal speech_status(status: String, message: String)
signal frame_received(texture: ImageTexture)

const TELEMETRY_PORT := 9999
const VIDEO_PORT := 9998
const HOST := "127.0.0.1"

# TCP Server for telemetry (Port 9999)
var tcp_server: TCPServer
var clients: Array[StreamPeerTCP] = []
var client_buffers: Dictionary = {}
var is_server_listening: bool = false

# Video TCP Client (Port 9998)
var video_client: StreamPeerTCP
var video_reconnect_timer: float = 0.0
var video_read_state: int = 0
var video_target_length: int = 0
var video_payload: PackedByteArray = PackedByteArray()
var current_frame_texture: ImageTexture = null

# Tracking status
var is_tracker_connected: bool = false
var last_telemetry_time: float = 0.0
var latest_telemetry: Dictionary = {}

# Cooldowns and debouncing
var last_gesture_time: Dictionary = {}
const ACTION_COOLDOWN: float = 0.45

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_telemetry_server()
	_init_video_client()

func _start_telemetry_server() -> void:
	tcp_server = TCPServer.new()
	var err := tcp_server.listen(TELEMETRY_PORT, HOST)
	if err == OK:
		is_server_listening = true
		print("[GestureListener] Telemetry server listening on %s:%d" % [HOST, TELEMETRY_PORT])
	elif err == ERR_ALREADY_IN_USE:
		is_server_listening = true
		print("[GestureListener] Telemetry port %d already open, listening..." % TELEMETRY_PORT)
	else:
		printerr("[GestureListener] Failed to bind TCP server on port %d: %d" % [TELEMETRY_PORT, err])

func _init_video_client() -> void:
	video_client = StreamPeerTCP.new()
	video_client.big_endian = true
	video_read_state = 0
	video_payload.clear()

func _process(delta: float) -> void:
	_poll_telemetry_server()
	_poll_video_stream(delta)
	
	# Connection timeout
	var now := Time.get_ticks_msec() / 1000.0
	if is_tracker_connected and (now - last_telemetry_time) > 3.0:
		is_tracker_connected = false
		tracker_disconnected.emit()
		print("[GestureListener] Tracker connection lost!")

func _poll_telemetry_server() -> void:
	if not is_server_listening or not tcp_server:
		return

	if tcp_server.is_connection_available():
		var new_client := tcp_server.take_connection()
		if new_client:
			clients.append(new_client)
			client_buffers[new_client] = ""
			is_tracker_connected = true
			last_telemetry_time = Time.get_ticks_msec() / 1000.0
			tracker_connected.emit()
			print("[GestureListener] Tracker client connected on port 9999!")

	var disconnected: Array[StreamPeerTCP] = []
	for client in clients:
		client.poll()
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			disconnected.append(client)
			continue

		var avail := client.get_available_bytes()
		if avail > 0:
			var data := client.get_utf8_string(avail)
			if data != "":
				var buf: String = client_buffers.get(client, "") + data
				while "\n" in buf:
					var parts := buf.split("\n", true, 1)
					var line := parts[0].strip_edges()
					buf = parts[1] if parts.size() > 1 else ""
					if line.length() > 0:
						_parse_json_message(line)
				client_buffers[client] = buf

	for dc in disconnected:
		clients.erase(dc)
		client_buffers.erase(dc)
		if clients.is_empty():
			is_tracker_connected = false
			tracker_disconnected.emit()

func _parse_json_message(line: String) -> void:
	var json = JSON.new()
	var err := json.parse(line)
	if err != OK:
		return

	var msg = json.data
	if not msg is Dictionary:
		return

	last_telemetry_time = Time.get_ticks_msec() / 1000.0
	if not is_tracker_connected:
		is_tracker_connected = true
		tracker_connected.emit()

	var msg_type: String = msg.get("type", "")
	if msg_type == "telemetry":
		latest_telemetry = msg
		telemetry_updated.emit(msg)
		
		# Face
		var face: Dictionary = msg.get("face", {})
		if face.get("active", false):
			var expr: String = face.get("expression", "neutral")
			var scores: Dictionary = face.get("scores", {})
			var eye_closed: float = face.get("eye_closed_duration", 0.0)
			face_detected.emit(expr, scores, eye_closed)

		# Hand
		var hand: Dictionary = msg.get("hand", {})
		if hand.get("active", false):
			var cur := Vector2(hand.get("cursor_x", 0.5), hand.get("cursor_y", 0.5))
			var swipe: String = hand.get("swipe", "none")
			var waving: bool = hand.get("is_waving", false)
			var wave_spd: float = hand.get("wave_speed", 0.0)
			var reach: bool = hand.get("reach_up", false)
			var open_p: bool = hand.get("is_open_palm", false)
			var fist_p: bool = hand.get("is_fist", false)
			hand_detected.emit(cur, swipe, waving, wave_spd, reach, open_p, fist_p)

		# Pose
		var pose: Dictionary = msg.get("pose", {})
		if pose.get("active", false):
			var gest: String = pose.get("gesture", "neutral")
			var lean: String = pose.get("lean", "neutral")
			var lean_amt: float = pose.get("lean_amount", 0.0)
			var hr: bool = pose.get("hands_raised", false)
			var ae: bool = pose.get("arms_extended", false)
			var sq: bool = pose.get("squatting", false)
			var cd: bool = pose.get("chicken_dance", false)
			pose_detected.emit(gest, lean, lean_amt, hr, ae, sq, cd)

	elif msg_type == "speech_result":
		speech_result.emit(msg.get("success", false), msg.get("text", ""), msg.get("audio_file", ""))
	elif msg_type == "speech_status":
		speech_status.emit(msg.get("status", ""), msg.get("message", ""))

func _poll_video_stream(delta: float) -> void:
	if not video_client:
		return
	video_client.poll()
	var status := video_client.get_status()

	if status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
		video_reconnect_timer += delta
		if video_reconnect_timer >= 1.5:
			video_reconnect_timer = 0.0
			video_read_state = 0
			video_payload.clear()
			video_client.connect_to_host(HOST, VIDEO_PORT)
			video_client.big_endian = true
		return

	if status != StreamPeerTCP.STATUS_CONNECTED:
		return

	# Loop while complete frames or chunks can be assembled
	while video_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		# State 0: Read 4-byte big-endian frame size
		if video_read_state == 0:
			if video_client.get_available_bytes() < 4:
				break
			video_target_length = video_client.get_32()
			if video_target_length <= 0 or video_target_length > 2_000_000:
				# Stream desynced or invalid header, reset buffer
				video_target_length = 0
				video_payload.clear()
				break
			video_read_state = 1
			video_payload.clear()

		# State 1: Read JPEG payload
		if video_read_state == 1:
			var avail := video_client.get_available_bytes()
			var needed := video_target_length - video_payload.size()
			if avail <= 0:
				break
			var to_read := mini(avail, needed)
			var chunk := video_client.get_data(to_read)
			if chunk[0] == OK:
				video_payload.append_array(chunk[1])
			else:
				video_read_state = 0
				video_payload.clear()
				break

			if video_payload.size() >= video_target_length:
				# Complete frame assembled! Verify JPEG magic bytes (0xFF 0xD8)
				if video_payload.size() >= 2 and video_payload[0] == 0xFF and video_payload[1] == 0xD8:
					var img := Image.new()
					var err := img.load_jpg_from_buffer(video_payload)
					if err == OK:
						if not current_frame_texture:
							current_frame_texture = ImageTexture.create_from_image(img)
						else:
							current_frame_texture.update(img)
						frame_received.emit(current_frame_texture)
				video_read_state = 0
				video_payload.clear()

func send_tracker_command(cmd: Dictionary) -> void:
	var msg := JSON.stringify(cmd) + "\n"
	for client in clients:
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			client.put_data(msg.to_utf8_buffer())

func request_speech_recognition() -> void:
	print("[GestureListener] Requesting Speech Recognition from Python tracker...")
	send_tracker_command({"action": "listen_speech"})

func request_pose_calibration() -> void:
	send_tracker_command({"action": "calibrate"})

# ------------------------------------------------------------------------------
# KEYBOARD TEST HARNESS & INJECTION
# Allows full keyboard verification of gestures during development & testing
# ------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1:
				face_detected.emit("smile", {"smile": 0.9}, 0.0)
			KEY_2:
				face_detected.emit("mouth_open", {"mouth_open": 0.8}, 0.0)
			KEY_3:
				face_detected.emit("eyebrows", {"eyebrows": 0.8}, 0.0)
			KEY_4:
				face_detected.emit("sleepy", {}, 1.5)
			KEY_5:
				face_detected.emit("surprised", {"mouth_open": 0.7, "eyebrows": 0.7}, 0.0)
			KEY_LEFT:
				hand_detected.emit(Vector2(0.3, 0.5), "swipe_left", false, 0.0, false, true, false)
			KEY_RIGHT:
				hand_detected.emit(Vector2(0.7, 0.5), "swipe_right", false, 0.0, false, true, false)
			KEY_UP:
				hand_detected.emit(Vector2(0.5, 0.2), "swipe_up", false, 0.0, true, true, false)
			KEY_W:
				hand_detected.emit(Vector2(0.5, 0.5), "none", true, 2.5, false, true, false)
			KEY_A:
				pose_detected.emit("lean_left", "lean_left", -0.2, false, false, false, false)
			KEY_D:
				pose_detected.emit("lean_right", "lean_right", 0.2, false, false, false, false)
			KEY_J:
				pose_detected.emit("hands_raised", "neutral", 0.0, true, false, false, false)
			KEY_B:
				pose_detected.emit("arms_extended", "neutral", 0.0, false, true, false, false)
			KEY_S:
				pose_detected.emit("squat", "neutral", 0.0, false, false, true, false)
			KEY_F:
				pose_detected.emit("lean_forward", "neutral", 0.0, false, false, false, false)
			KEY_C:
				pose_detected.emit("chicken_dance", "neutral", 0.0, false, false, false, true)
