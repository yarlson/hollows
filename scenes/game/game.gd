extends Node3D

const LEVELS: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
]
const FADE_DURATION: float = 0.4
const TRANSITION_HEAL: int = 25

var _game_over: bool = false
var _transitioning: bool = false
var _kills: int = 0
var _elapsed_time: float = 0.0
var _current_level_index: int = 0
var _current_level: Node3D = null

@onready var _player: CharacterBody3D = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _level_container: Node3D = $LevelContainer
@onready var _fade_rect: ColorRect = $FadeLayer/FadeRect


func _ready() -> void:
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_player.add_to_group(&"player")
	_player.health_changed.connect(_hud.update_health)
	_player.ammo_changed.connect(_hud.update_ammo)
	_player.hit_landed.connect(_hud.flash_hitmarker)
	_player.damage_taken_from.connect(_hud.show_damage_direction)
	_player.died.connect(_on_player_died)
	_hud.restart_requested.connect(_on_restart)
	_load_level(_current_level_index)
	_fade_in()


func _process(delta: float) -> void:
	if not _game_over and not _transitioning:
		_elapsed_time += delta


func _load_level(index: int) -> void:
	if _current_level:
		_current_level.queue_free()
		_current_level = null

	var scene: PackedScene = load(LEVELS[index])
	_current_level = scene.instantiate()
	_level_container.add_child(_current_level)

	_wire_level(_current_level)

	_hud.update_key_status(false)
	_hud.update_level(index + 1)

	var spawn: Marker3D = _current_level.get_node_or_null("SpawnPoint")
	if spawn:
		_player.global_transform.origin = spawn.global_transform.origin
		_player.rotation.y = spawn.rotation.y

	_player.reset_for_level()


func _wire_level(level: Node3D) -> void:
	var enemies: Node = level.get_node_or_null("Enemies")
	if enemies:
		for child: Node in enemies.get_children():
			if child.has_signal(&"died"):
				child.connect(&"died", _on_enemy_died)

	if level.has_signal(&"level_completed"):
		level.connect(&"level_completed", _on_level_completed)

	if level.has_method(&"setup"):
		level.setup(_player, _hud)


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tween.finished


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished


func _transition_to_next_level() -> void:
	_transitioning = true
	_player.set_process_unhandled_input(false)
	_player.set_physics_process(false)

	await _fade_out()

	_current_level_index += 1
	_load_level(_current_level_index)

	_player.velocity = Vector3.ZERO
	_player.heal(TRANSITION_HEAL)
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)

	_hud.flash_level_announcement(_current_level_index + 1)

	await _fade_in()

	_transitioning = false


func _on_enemy_died() -> void:
	_kills += 1
	_hud.update_kills(_kills)


func _on_level_completed() -> void:
	if _transitioning or _game_over:
		return
	var next_index := _current_level_index + 1
	if next_index >= LEVELS.size():
		_finish_game()
	else:
		_transition_to_next_level()


func _finish_game() -> void:
	_game_over = true
	_player.set_process_unhandled_input(false)
	_player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_victory(_kills, _elapsed_time, LEVELS.size())


func _on_player_died() -> void:
	_game_over = true
	_hud.show_game_over(_kills, _elapsed_time, _current_level_index + 1)


func _on_restart() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/game/game.tscn")
