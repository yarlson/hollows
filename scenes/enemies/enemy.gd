extends CharacterBody3D

signal died

enum State { IDLE, CHASE, ATTACK, DEAD }

const CHASE_SPEED: float = 4.0
const ATTACK_DAMAGE: int = 10
const ATTACK_COOLDOWN: float = 1.0
const DETECTION_RANGE: float = 15.0
const ATTACK_RANGE: float = 2.0

var _health: int = 30
var _state: State = State.IDLE
var _target: Node3D = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _attack_timer: Timer = $AttackTimer


func _ready() -> void:
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	_mesh.set_surface_override_material(0, _mesh.get_surface_override_material(0).duplicate())


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	_update_target_state()

	match _state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
		State.CHASE:
			_chase()
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()


func take_damage(amount: int) -> void:
	if _state == State.DEAD:
		return
	_health -= amount
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
	# Find player if we don't have a target
	if not _target_is_alive():
		if _state != State.IDLE:
			_attack_timer.stop()
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
				_do_attack()
				_attack_timer.start(ATTACK_COOLDOWN)
			elif dist > DETECTION_RANGE:
				_target = null
				_state = State.IDLE
		State.ATTACK:
			if dist > ATTACK_RANGE * 1.5:
				_attack_timer.stop()
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


func _do_attack() -> void:
	if not _target_is_alive():
		_attack_timer.stop()
		_target = null
		_state = State.IDLE
		return
	if _target.has_method(&"take_damage"):
		_target.take_damage(ATTACK_DAMAGE)


func _on_attack_timer_timeout() -> void:
	if _state == State.ATTACK:
		_do_attack()


func _flash_hit() -> void:
	var mat: StandardMaterial3D = _mesh.get_surface_override_material(0)
	mat.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and _state != State.DEAD:
		mat.albedo_color = Color(0.4, 0.0, 0.0)


func _die() -> void:
	_state = State.DEAD
	_attack_timer.stop()
	died.emit()
	queue_free()
