extends CharacterBody3D

signal health_changed(new_health: int, max_health: int)
signal hit_landed
signal damage_taken_from(angle: float)
signal died

const SPEED: float = 7.0
const JUMP_VELOCITY: float = 4.5
const ACCELERATION: float = 10.0
const FRICTION: float = 10.0
const DAMAGE: int = 10
const FIRE_RATE: float = 0.2
const DEGREES_PER_UNIT: float = 0.001

@export_range(1, 100, 1) var mouse_sensitivity: int = 50

var _health: int = 100
var _max_health: int = 100
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _mouse_captured: bool = true
var _can_shoot: bool = true

@onready var _head: Node3D = $Head
@onready var _raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var _muzzle_flash: OmniLight3D = $Head/Camera3D/MuzzleFlash
@onready var _damage_overlay: ColorRect = $DamageOverlay
@onready var _shoot_sfx: AudioStreamPlayer = $ShootSFX
@onready var _hurt_sfx: AudioStreamPlayer = $HurtSFX


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_raycast.enabled = true
	_shoot_sfx.stream = _make_noise(0.06, 4000.0, 0.4)
	_hurt_sfx.stream = _make_noise(0.12, 800.0, 0.5)
	health_changed.emit(_health, _max_health)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if _mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true
		return

	if event is InputEventMouseMotion:
		var motion: Vector2 = event.screen_relative * mouse_sensitivity * DEGREES_PER_UNIT
		rotate_y(-deg_to_rad(motion.x))
		_head.rotate_x(-deg_to_rad(motion.y))
		_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed(&"shoot"):
		_shoot()

	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction:
		velocity.x = lerpf(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = lerpf(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, FRICTION * delta)
		velocity.z = lerpf(velocity.z, 0.0, FRICTION * delta)

	move_and_slide()


func take_damage(amount: int, source_position := Vector3.INF) -> void:
	if _health <= 0:
		return
	_health -= amount
	health_changed.emit(_health, _max_health)
	_flash_damage()
	if source_position.is_finite():
		_emit_damage_direction(source_position)
	if _health <= 0:
		_die()


func heal(amount: int) -> void:
	_health = mini(_health + amount, _max_health)
	health_changed.emit(_health, _max_health)


func _shoot() -> void:
	if not _can_shoot:
		return
	_can_shoot = false
	_raycast.force_raycast_update()
	if _raycast.is_colliding():
		var collider := _raycast.get_collider()
		if collider.has_method(&"take_damage"):
			collider.take_damage(DAMAGE)
			hit_landed.emit()
	_flash_muzzle()
	_shoot_sfx.play()
	await get_tree().create_timer(FIRE_RATE).timeout
	_can_shoot = true


func _flash_muzzle() -> void:
	_muzzle_flash.visible = true
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(self):
		_muzzle_flash.visible = false


func _flash_damage() -> void:
	_damage_overlay.visible = true
	_hurt_sfx.play()
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		_damage_overlay.visible = false


func _make_noise(duration: float, freq: float, vol: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - (t / duration)
		var sample := sin(t * freq * TAU) * 0.5 + (randf() - 0.5)
		sample *= envelope * vol
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream


func _emit_damage_direction(source_position: Vector3) -> void:
	var to_source := source_position - global_position
	to_source.y = 0.0
	if to_source.length_squared() < 0.01:
		return
	to_source = to_source.normalized()
	var forward := -transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var angle := atan2(to_source.dot(right), to_source.dot(forward))
	damage_taken_from.emit(angle)


func _die() -> void:
	died.emit()
	collision_layer = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false
	set_physics_process(false)
	set_process_unhandled_input(false)
