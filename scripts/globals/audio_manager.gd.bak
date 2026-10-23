extends Node

## WIGGLE WARS! — Global Audio Manager
## Handles BGM, SFX, Voice narration, procedural chimes/sounds,
## volume controls, audio ducking, and subtitle events.

signal subtitle_requested(text: String, duration: float)

var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels: int = 8

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var voice_volume: float = 1.0
var is_muted: bool = false

# Procedural sound cache
var procedural_sounds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "Master"
	add_child(voice_player)
	
	for i in range(max_sfx_channels):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
		
	_generate_procedural_sounds()

func _generate_procedural_sounds() -> void:
	# 1. Chime / Sparkle (Face Frenzy / Star Burst / Reward)
	procedural_sounds["chime"] = _synth_tone_sequence([523.25, 659.25, 783.99, 1046.50], 0.12, 0.4)
	
	# 2. Bubble Pop (Mouth Open)
	procedural_sounds["bubble_pop"] = _synth_frequency_slide(300.0, 750.0, 0.12, 0.5)
	
	# 3. Bloom / Glow (Smile)
	procedural_sounds["bloom"] = _synth_tone_sequence([440.0, 554.37, 659.25], 0.15, 0.4)
	
	# 4. Wind Gust (Surprised)
	procedural_sounds["wind_gust"] = _synth_noise_whoosh(0.5, 0.35)
	
	# 5. Sleepy Chime (Eye Closed)
	procedural_sounds["sleepy"] = _synth_tone_sequence([392.0, 329.63, 261.63], 0.25, 0.3)
	
	# 6. Fruit Slice Swish (Fruit Ninja)
	procedural_sounds["swish"] = _synth_noise_whoosh(0.18, 0.6)
	
	# 7. Juicy Splash (Fruit Ninja)
	procedural_sounds["splash"] = _synth_frequency_slide(600.0, 180.0, 0.20, 0.6)
	
	# 8. Combo Fanfare (Level 2 Combo)
	procedural_sounds["combo"] = _synth_tone_sequence([587.33, 739.99, 880.0, 1174.66], 0.08, 0.5)
	
	# 9. Bomb Explosion (Distinct punchy blast)
	procedural_sounds["bomb"] = _synth_explosion(0.50, 0.8)
	
	# 10. Penguin Chirp (Waddle Wars)
	procedural_sounds["chirp"] = _synth_frequency_slide(880.0, 1320.0, 0.15, 0.45)
	
	# 11. Penguin Jump / Slide
	procedural_sounds["jump"] = _synth_frequency_slide(220.0, 520.0, 0.18, 0.4)
	procedural_sounds["slide"] = _synth_noise_whoosh(0.35, 0.3)
	
	# 12. Crystal & Fish Collect
	procedural_sounds["crystal"] = _synth_tone_sequence([880.0, 1174.66, 1760.0], 0.09, 0.5)
	procedural_sounds["fish"] = _synth_frequency_slide(360.0, 950.0, 0.18, 0.55)
	
	# 13. Toy Spring / Boing (Copycat Chaos)
	procedural_sounds["boing"] = _synth_frequency_slide(200.0, 600.0, 0.25, 0.5)
	
	# 14. Wheel Click (Lucky Chaos Wheel)
	procedural_sounds["wheel_click"] = _synth_click(0.04, 0.4)
	
	# 15. Wheel Win Fanfare
	procedural_sounds["wheel_win"] = _synth_tone_sequence([523.25, 659.25, 783.99, 1046.50, 1318.51], 0.14, 0.6)
	
	# 16. Duck Quack
	procedural_sounds["quack"] = _synth_frequency_slide(400.0, 280.0, 0.22, 0.5)
	
	# 17. Victory Fanfare (Surprise Wonderland)
	procedural_sounds["legend_fanfare"] = _synth_tone_sequence([440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51], 0.18, 0.7)

func play_sfx(sound_name: String) -> void:
	if is_muted:
		return
	var stream: AudioStream = procedural_sounds.get(sound_name, null)
	if not stream:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(sfx_volume * master_volume)
			p.play()
			return
	# If all busy, steal first player
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = linear_to_db(sfx_volume * master_volume)
	sfx_players[0].play()

func play_voice_file(file_path: String, subtitle_text: String = "", duration: float = 4.0) -> void:
	if is_muted:
		return
	if subtitle_text != "":
		subtitle_requested.emit(subtitle_text, duration)
	
	if voice_player.playing:
		voice_player.stop()

	var stream := _load_audio_stream(file_path)
	if stream:
		voice_player.stream = stream
		voice_player.volume_db = linear_to_db(voice_volume * master_volume)
		voice_player.play()
		# Duck music slightly
		if music_player.playing:
			music_player.volume_db = linear_to_db(music_volume * master_volume * 0.4)
		return

	# Graceful fallback: play gentle chime and display subtitle without error
	play_sfx("chime")
	print("[AudioManager Voice Fallback] Subtitle: '%s'" % subtitle_text)

func _load_audio_stream(file_path: String) -> AudioStream:
	if ResourceLoader.exists(file_path):
		var res = load(file_path)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(file_path):
		return _load_wav_from_file(file_path)
	return null

func _load_wav_from_file(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44:
		return null
	if bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	if bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return null
	
	var pos := 12
	var channels := 1
	var sample_rate := 22050
	var bits_per_sample := 16
	var data_start := -1
	var data_size := 0
	
	while pos + 8 <= bytes.size():
		var chunk_id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_len := bytes.decode_u32(pos + 4)
		if chunk_id == "fmt ":
			channels = bytes.decode_u16(pos + 10)
			sample_rate = bytes.decode_u32(pos + 12)
			bits_per_sample = bytes.decode_u16(pos + 22)
		elif chunk_id == "data":
			data_start = pos + 8
			data_size = chunk_len
			break
		pos += 8 + chunk_len
	
	if data_start < 0 or data_start + data_size > bytes.size():
		return null
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 else AudioStreamWAV.FORMAT_8_BITS
	wav.stereo = (channels == 2)
	wav.mix_rate = sample_rate
	wav.data = bytes.slice(data_start, data_start + data_size)
	return wav

func stop_voice() -> void:
	if voice_player.playing:
		voice_player.stop()
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

func play_music_file(file_path: String, vol_mult: float = 0.75, loop: bool = true) -> void:
	if is_muted:
		return
	var stream := _load_audio_stream(file_path)
	if stream:
		if stream is AudioStreamMP3:
			stream.loop = loop
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume * master_volume * vol_mult)
		music_player.play()

func duck_music(duck_ratio: float = 0.25) -> void:
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume * master_volume * duck_ratio)

func unduck_music(vol_mult: float = 0.75) -> void:
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume * master_volume * vol_mult)

func pause_music() -> void:
	if music_player.playing:
		music_player.stream_paused = true

func resume_music() -> void:
	if music_player.stream_paused:
		music_player.stream_paused = false
	elif music_player.stream != null and not music_player.playing:
		music_player.play()

func stop_music() -> void:
	if music_player.playing:
		music_player.stop()

func play_music_procedural(theme: String) -> void:
	if is_muted or music_player.playing:
		return
	# Cheerful party synth arpeggio progression (C - G - Am - F)
	var chord_c := [261.63, 329.63, 392.0, 523.25]
	var chord_g := [196.0, 246.94, 293.66, 392.0]
	var chord_am := [220.0, 261.63, 329.63, 440.0]
	var chord_f := [174.61, 220.0, 261.63, 349.23]
	var all_notes := []
	for c in [chord_c, chord_g, chord_am, chord_f]:
		for n in c:
			all_notes.append(n)
	var bgm_stream := _synth_tone_sequence(all_notes, 0.18, 0.25)
	bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm_stream.loop_end = bgm_stream.data.size() / 2
	music_player.stream = bgm_stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.play()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_update_volumes()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_update_volumes()

func set_voice_volume(v: float) -> void:
	voice_volume = clampf(v, 0.0, 1.0)
	_update_volumes()

func set_mute(muted: bool) -> void:
	is_muted = muted
	_update_volumes()

func _update_volumes() -> void:
	if is_muted:
		music_player.volume_db = -80.0
		voice_player.volume_db = -80.0
		for p in sfx_players:
			p.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		voice_player.volume_db = linear_to_db(voice_volume * master_volume)
		for p in sfx_players:
			p.volume_db = linear_to_db(sfx_volume * master_volume)

# ------------------------------------------------------------------------------
# SYNTHESIS HELPERS (Generates pristine 16-bit PCM AudioStreamWAV)
# ------------------------------------------------------------------------------
func _synth_tone_sequence(freqs: Array, step_duration: float, max_vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(freqs.size() * step_duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var idx := 0
	for f in freqs:
		var step_samples := int(step_duration * sample_rate)
		for i in range(step_samples):
			var t := float(i) / sample_rate
			var env := sin((float(i) / step_samples) * PI) # envelope
			var val := sin(2.0 * PI * float(f) * t) * env * max_vol
			var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
			data.encode_s16(idx * 2, sample)
			idx += 1

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _synth_frequency_slide(start_f: float, end_f: float, duration: float, max_vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var phase := 0.0
	for i in range(total_samples):
		var frac := float(i) / total_samples
		var cur_f := lerpf(start_f, end_f, frac)
		phase += 2.0 * PI * cur_f / sample_rate
		var env := sin(frac * PI)
		var val := sin(phase) * env * max_vol
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _synth_noise_whoosh(duration: float, max_vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var rng := RandomNumberGenerator.new()
	for i in range(total_samples):
		var frac := float(i) / total_samples
		var env := sin(frac * PI)
		var val := rng.randf_range(-1.0, 1.0) * env * max_vol
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _synth_buzzer(freq: float, duration: float, max_vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / sample_rate
		var frac := float(i) / total_samples
		var env := (1.0 - frac)
		# Square wave
		var val := (1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0) * env * max_vol
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _synth_click(duration: float, max_vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var frac := float(i) / total_samples
		var env := (1.0 - frac) * (1.0 - frac)
		var val := sin(2.0 * PI * 1800.0 * (float(i) / sample_rate)) * env * max_vol
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _synth_explosion(duration: float, max_vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var phase := 0.0

	for i in range(total_samples):
		var frac := float(i) / total_samples
		var env := exp(-frac * 6.5)
		# Rapidly descending low rumble
		var freq := lerpf(160.0, 32.0, pow(frac, 0.4))
		phase += 2.0 * PI * freq / sample_rate
		var rumble := sin(phase) * 0.7
		# Explosive crackle noise burst
		var noise := rng.randf_range(-1.0, 1.0) * 0.8
		var val := (rumble + noise) * env * max_vol
		var sample := int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
