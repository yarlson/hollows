extends Area3D

signal picked_up

@export var heal_amount: int = 25

var _rotation_speed: float = 2.0
var _pickup_sfx: AudioStreamWAV = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_pickup_sfx = _make_pickup_sound()


func _process(delta: float) -> void:
	rotation.y += _rotation_speed * delta


func _on_body_entered(body: Node3D) -> void:
	if body.has_method(&"heal"):
		body.heal(heal_amount)
		picked_up.emit()
		_play_pickup_sound()
		queue_free()


func _play_pickup_sound() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = _pickup_sfx
	sfx.volume_db = -6.0
	get_parent().add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)


func _make_pickup_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.2
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - t / duration
		var freq := 600.0 + t * 1200.0
		var sample := sin(t * freq * TAU) * envelope * 0.35
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream
