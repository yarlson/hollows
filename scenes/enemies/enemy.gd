extends CharacterBody3D

signal died

enum State { IDLE, CHASE, ATTACK, DEAD }

const CHASE_SPEED: float = 4.0
const ATTACK_DAMAGE: int = 10
const ATTACK_COOLDOWN: float = 1.0

var _health: int = 30
var _state: State = State.IDLE
var _target: Node3D = null
var _is_attacking: bool = false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _detection_area: Area3D = $DetectionArea
@onready var _attack_area: Area3D = $AttackArea
@onready var _nav_timer: Timer = $NavUpdateTimer


func _ready() -> void:
	_detection_area.body_entered.connect(_on_detection_body_entered)
	_detection_area.body_exited.connect(_on_detection_body_exited)
	_attack_area.body_entered.connect(_on_attack_body_entered)
	_attack_area.body_exited.connect(_on_attack_body_exited)
	_nav_timer.timeout.connect(_on_nav_timer_timeout)
	_mesh.set_surface_override_material(0, _mesh.get_surface_override_material(0).duplicate())


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

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


func _chase() -> void:
	if not is_instance_valid(_target):
		_state = State.IDLE
		return
	if _nav_agent.is_navigation_finished():
		return
	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity.x = direction.x * CHASE_SPEED
	velocity.z = direction.z * CHASE_SPEED
	var look_target := Vector3(
		_target.global_position.x, global_position.y, _target.global_position.z
	)
	if global_position.distance_squared_to(look_target) > 0.01:
		look_at(look_target, Vector3.UP)


func _attack_loop() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	while _state == State.ATTACK and is_instance_valid(self):
		if not is_instance_valid(_target) or _target.collision_layer == 0:
			_state = State.IDLE
			break
		if _target.has_method(&"take_damage"):
			_target.take_damage(ATTACK_DAMAGE)
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	_is_attacking = false


func _flash_hit() -> void:
	var mat: StandardMaterial3D = _mesh.get_surface_override_material(0)
	mat.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and _state != State.DEAD:
		mat.albedo_color = Color(0.4, 0.0, 0.0)


func _die() -> void:
	_state = State.DEAD
	died.emit()
	queue_free()


func _on_detection_body_entered(body: Node3D) -> void:
	if _state == State.IDLE:
		_target = body
		_state = State.CHASE
		_nav_agent.target_position = _target.global_position


func _on_detection_body_exited(body: Node3D) -> void:
	if body == _target and _state in [State.CHASE, State.ATTACK]:
		_target = null
		_state = State.IDLE


func _on_attack_body_entered(body: Node3D) -> void:
	if body == _target and _state == State.CHASE:
		_state = State.ATTACK
		_attack_loop()


func _on_attack_body_exited(body: Node3D) -> void:
	if body == _target and _state == State.ATTACK:
		if is_instance_valid(_target):
			_state = State.CHASE
		else:
			_state = State.IDLE


func _on_nav_timer_timeout() -> void:
	if _state == State.CHASE and is_instance_valid(_target):
		_nav_agent.target_position = _target.global_position
