extends Node3D

signal level_completed

var _has_key: bool = false
var _completed: bool = false
var _player: CharacterBody3D = null
var _hud: CanvasLayer = null
var _key_sfx: AudioStreamPlayer = null
var _door_sfx: AudioStreamPlayer = null
var _ambient_sfx: AudioStreamPlayer = null

@onready var _key_pickup: Area3D = $KeyPickup
@onready var _door: StaticBody3D = $Door
@onready var _exit_trigger: Area3D = $ExitTrigger


func setup(player: CharacterBody3D, hud: CanvasLayer) -> void:
	_player = player
	_hud = hud


func _ready() -> void:
	_key_pickup.picked_up.connect(_on_key_collected)
	_exit_trigger.body_entered.connect(_on_exit_reached)
	_key_sfx = AudioStreamPlayer.new()
	_key_sfx.stream = _make_key_chime()
	_key_sfx.volume_db = -6.0
	add_child(_key_sfx)
	_door_sfx = AudioStreamPlayer.new()
	_door_sfx.stream = _make_door_sound()
	_door_sfx.volume_db = -3.0
	add_child(_door_sfx)
	_ambient_sfx = AudioStreamPlayer.new()
	var music: AudioStreamMP3 = load("res://assets/audio/labyrinth_breathes.mp3")
	music.loop = true
	_ambient_sfx.stream = music
	_ambient_sfx.volume_db = -12.0
	add_child(_ambient_sfx)
	_ambient_sfx.play()


func _on_key_collected() -> void:
	_has_key = true
	if _hud:
		_hud.update_key_status(true)
		_hud.flash_key_status()
	_key_sfx.play()
	_door.collision_layer = 0
	_door.collision_mask = 0
	var tween := create_tween()
	(
		tween
		. tween_property(_door, "position:y", _door.position.y + 4.0, 0.8)
		. set_ease(Tween.EASE_IN)
		. set_trans(Tween.TRANS_QUAD)
	)
	tween.tween_callback(_door.queue_free)
	_door_sfx.play()


func _on_exit_reached(body: Node3D) -> void:
	if body.is_in_group(&"player") and _has_key and not _completed:
		_completed = true
		level_completed.emit()


func _make_key_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.35
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := (1.0 - t / duration) * (1.0 - t / duration)
		var freq := 523.0 if t < 0.15 else 659.0
		var sample := sin(t * freq * TAU) * envelope * 0.4
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream


func _make_door_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.6
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - t / duration
		var sine := sin(t * 80.0 * TAU) * 0.5
		var noise := (randf() * 2.0 - 1.0) * 0.3
		var sample := (sine + noise) * envelope * 0.5
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream
