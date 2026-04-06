extends Node3D

var _game_over: bool = false
var _has_key: bool = false
var _kills: int = 0
var _elapsed_time: float = 0.0

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
	_door.queue_free()


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
