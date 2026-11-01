class_name PartySound
extends Node

var enabled: bool = true:
	set(value):
		enabled = value
		if is_instance_valid(music): music.stream_paused = not value
var samples: Dictionary = {}
var music: AudioStreamPlayer

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enabled = false
		return
	for sound in ["jump", "star", "item", "fall", "win", "click", "check", "count"]:
		samples[sound] = make_sample(sound)
	music = AudioStreamPlayer.new()
	music.stream = make_music()
	music.volume_db = -22
	add_child(music)
	music.play()
	music.stream_paused = not enabled

func make_music() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 880.0, 698.46,
		523.25, 659.25, 783.99, 1046.5, 880.0, 783.99, 659.25, 587.33,
		440.0, 523.25, 659.25, 783.99, 698.46, 587.33, 523.25, 440.0,
		392.0, 523.25, 659.25, 587.33, 523.25, 0.0, 392.0, 0.0]
	var rate: int = 22050
	var beat: float = 0.30
	var duration: float = notes.size() * beat
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var note_index := mini(notes.size() - 1, int(t / beat))
		var local := fmod(t, beat)
		var frequency: float = notes[note_index]
		var envelope := minf(local * 200, 1) * exp(-local * 12)
		var melody := (sin(TAU * frequency * local) + sin(TAU * frequency * 3 * local) * 0.14) * envelope
		var bass_frequency: float = [130.81, 146.83, 110.0, 130.81][int(note_index / 8)]
		var bass := sin(TAU * bass_frequency * t) * 0.18 * exp(-fmod(t, beat * 2) * 6)
		bytes.encode_s16(i * 2, int((melody * 0.42 + bass) * 18000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func make_sample(kind: String) -> AudioStreamWAV:
	var duration: float = 0.14
	var frequency: float = 620
	match kind:
		"jump": frequency = 470; duration = 0.17
		"star": frequency = 1100; duration = 0.16
		"item": frequency = 790; duration = 0.24
		"fall": frequency = 300; duration = 0.34
		"win": frequency = 660; duration = 0.70
		"click": frequency = 800; duration = 0.065
		"check": frequency = 880; duration = 0.36
		"count": frequency = 500; duration = 0.11
	var rate: int = 22050
	var bytes := PackedByteArray()
	bytes.resize(int(duration * rate) * 2)
	for i in range(bytes.size() / 2):
		var t := float(i) / rate
		var pitch := frequency
		if kind == "jump": pitch += t * 2200
		if kind == "fall": pitch -= t * 570
		if kind == "win": pitch *= [1.0, 1.25, 1.5, 2.0][mini(3, int(t * 6))]
		var envelope := minf(1.0, t * 90) * pow(1.0 - t / duration, 1.7)
		var value := (sin(TAU * pitch * t) + 0.18 * sin(TAU * pitch * t * 2.0)) * envelope * 0.20
		bytes.encode_s16(i * 2, int(value * 32767))
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = rate
	sample.data = bytes
	return sample

func play(kind: String) -> void:
	if not enabled or not samples.has(kind):
		return
	var player := AudioStreamPlayer.new()
	player.stream = samples[kind]
	player.volume_db = -7
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
