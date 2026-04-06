extends CharacterBody3D

signal health_changed(new_health: int, max_health: int)
signal died

const SPEED: float = 7.0
const JUMP_VELOCITY: float = 4.5
const ACCELERATION: float = 10.0
const FRICTION: float = 10.0
const DAMAGE: int = 10
const DEGREES_PER_UNIT: float = 0.001

@export_range(1, 100, 1) var mouse_sensitivity: int = 50

var _health: int = 100
var _max_health: int = 100
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _mouse_captured: bool = true

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _raycast: RayCast3D = $Head/Camera3D/RayCast3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_raycast.enabled = true


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


func take_damage(amount: int) -> void:
	if _health <= 0:
		return
	_health -= amount
	health_changed.emit(_health, _max_health)
	if _health <= 0:
		_die()


func _shoot() -> void:
	_raycast.force_raycast_update()
	if _raycast.is_colliding():
		var collider := _raycast.get_collider()
		if collider.has_method(&"take_damage"):
			collider.take_damage(DAMAGE)


func _die() -> void:
	died.emit()
	collision_layer = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false
	set_physics_process(false)
	set_process_unhandled_input(false)
