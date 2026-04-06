extends Node3D

var _game_over: bool = false
var _has_key: bool = false
var _kills: int = 0
var _elapsed_time: float = 0.0
var _key_sfx: AudioStreamPlayer = null
var _door_sfx: AudioStreamPlayer = null
var _ambient_sfx: AudioStreamPlayer = null

@onready var _player: CharacterBody3D = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _key_pickup: Area3D = $KeyPickup
@onready var _door: StaticBody3D = $Door
@onready var _exit_trigger: Area3D = $ExitTrigger


func _ready() -> void:
	_player.add_to_group(&"player")
	_player.health_changed.connect(_hud.update_health)
	_player.hit_landed.connect(_hud.flash_hitmarker)
	_player.damage_taken_from.connect(_hud.show_damage_direction)
	_player.died.connect(_on_player_died)
	_hud.restart_requested.connect(_on_restart)
	_wire_enemies()
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
	_ambient_sfx.stream = _make_ambient_drone()
	_ambient_sfx.volume_db = -18.0
	add_child(_ambient_sfx)
	_ambient_sfx.play()


func _wire_enemies() -> void:
	for child: Node in $Enemies.get_children():
		if child.has_signal(&"died"):
			child.connect(&"died", _on_enemy_died)


func _on_enemy_died() -> void:
	_kills += 1
	_hud.update_kills(_kills)


func _process(delta: float) -> void:
	if not _game_over:
		_elapsed_time += delta


func _on_key_collected() -> void:
	_has_key = true
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
	if body.is_in_group(&"player") and _has_key and not _game_over:
		_game_over = true
		_player.set_process_unhandled_input(false)
		_player.set_physics_process(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_hud.show_victory(_kills, _elapsed_time)


func _on_player_died() -> void:
	_game_over = true
	_hud.show_game_over(_kills, _elapsed_time)


func _on_restart() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/labyrinth.tscn")


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


func _make_ambient_drone() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 2.0
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var s1 := sin(t * 55.0 * TAU) * 0.3
		var s2 := sin(t * 82.5 * TAU) * 0.15
		var noise := (randf() * 2.0 - 1.0) * 0.05
		var sample := (s1 + s2 + noise) * 0.4
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples
	return stream
