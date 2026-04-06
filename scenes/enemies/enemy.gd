extends CharacterBody3D

signal died

enum State { IDLE, CHASE, ATTACK, DEAD }

const CHASE_SPEED: float = 4.0
const ATTACK_DAMAGE: int = 5
const ATTACK_COOLDOWN: float = 1.0
const DETECTION_RANGE: float = 15.0
const ATTACK_RANGE: float = 2.0
const STAGGER_DURATION: float = 0.15
const TELEGRAPH_DURATION: float = 0.3
const LUNGE_SPEED: float = 8.0
const NORMAL_COLOR := Color(0.4, 0.0, 0.0)
const TELEGRAPH_COLOR := Color(1.0, 0.5, 0.0)

var _health: int = 30
var _state: State = State.IDLE
var _stagger_time: float = 0.0
var _target: Node3D = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _attack_timer: Timer = $AttackTimer
@onready var _telegraph_timer: Timer = $TelegraphTimer
@onready var _hit_sfx: AudioStreamPlayer3D = $HitSFX


func _ready() -> void:
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	_telegraph_timer.timeout.connect(_on_telegraph_timeout)
	_mesh.set_surface_override_material(0, _mesh.get_surface_override_material(0).duplicate())
	_hit_sfx.stream = _make_hit_sound()


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _stagger_time > 0.0:
		_stagger_time -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	_update_target_state()

	match _state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
		State.CHASE:
			_chase()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, LUNGE_SPEED * 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, LUNGE_SPEED * 4.0 * delta)

	move_and_slide()


func take_damage(amount: int) -> void:
	if _state == State.DEAD:
		return
	_health -= amount
	_stagger_time = STAGGER_DURATION
	_flash_hit()
	if _health <= 0:
		_die()


func _target_is_alive() -> bool:
	return is_instance_valid(_target) and _target.collision_layer != 0


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group(&"player"):
		if node.collision_layer != 0:
			return node
	return null


func _update_target_state() -> void:
	if not _target_is_alive():
		if _state != State.IDLE:
			_attack_timer.stop()
			_telegraph_timer.stop()
			_state = State.IDLE
		_target = _find_player()
		if _target == null:
			return

	var dist := _flat_distance_to(_target)

	match _state:
		State.IDLE:
			if dist < DETECTION_RANGE:
				_state = State.CHASE
		State.CHASE:
			if dist < ATTACK_RANGE:
				_state = State.ATTACK
				_begin_telegraph()
				_attack_timer.start(ATTACK_COOLDOWN)
			elif dist > DETECTION_RANGE:
				_target = null
				_state = State.IDLE
		State.ATTACK:
			if dist > ATTACK_RANGE * 1.5:
				_telegraph_timer.stop()
				_attack_timer.stop()
				_set_color(NORMAL_COLOR)
				_state = State.CHASE


func _chase() -> void:
	var direction := _flat_direction_to(_target)
	if direction.length_squared() > 0.01:
		velocity.x = direction.x * CHASE_SPEED
		velocity.z = direction.z * CHASE_SPEED
		look_at(
			Vector3(_target.global_position.x, global_position.y, _target.global_position.z),
			Vector3.UP,
		)


func _flat_distance_to(target: Node3D) -> float:
	var a := Vector2(global_position.x, global_position.z)
	var b := Vector2(target.global_position.x, target.global_position.z)
	return a.distance_to(b)


func _flat_direction_to(target: Node3D) -> Vector3:
	return (
		Vector3(
			target.global_position.x - global_position.x,
			0.0,
			target.global_position.z - global_position.z,
		)
		. normalized()
	)


func _begin_telegraph() -> void:
	if not _target_is_alive():
		_attack_timer.stop()
		_target = null
		_state = State.IDLE
		return
	_set_color(TELEGRAPH_COLOR)
	_telegraph_timer.start(TELEGRAPH_DURATION)


func _on_telegraph_timeout() -> void:
	if _state != State.ATTACK:
		return
	_set_color(NORMAL_COLOR)
	if not _target_is_alive():
		return
	var direction := _flat_direction_to(_target)
	velocity.x = direction.x * LUNGE_SPEED
	velocity.z = direction.z * LUNGE_SPEED
	if _target.has_method(&"take_damage"):
		_target.take_damage(ATTACK_DAMAGE, global_position)


func _on_attack_timer_timeout() -> void:
	if _state == State.ATTACK:
		_begin_telegraph()


func _set_color(color: Color) -> void:
	var mat: StandardMaterial3D = _mesh.get_surface_override_material(0)
	mat.albedo_color = color


func _flash_hit() -> void:
	_set_color(Color.WHITE)
	_hit_sfx.play()
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and _state != State.DEAD:
		_set_color(NORMAL_COLOR)


func _make_hit_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.08
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - (t / duration)
		var freq := 1200.0 - t * 8000.0
		var sample := sin(t * freq * TAU) * envelope * 0.5
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream


func _die() -> void:
	_state = State.DEAD
	_attack_timer.stop()
	_telegraph_timer.stop()
	died.emit()
	collision_layer = 0
	collision_mask = 0
	_set_color(Color.WHITE)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
	tween.tween_callback(queue_free)
