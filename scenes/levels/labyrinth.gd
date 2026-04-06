extends Node3D

var _game_over: bool = false
var _kills: int = 0
var _elapsed_time: float = 0.0

@onready var _player: CharacterBody3D = $Player
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	_player.add_to_group(&"player")
	_player.health_changed.connect(_hud.update_health)
	_player.hit_landed.connect(_hud.flash_hitmarker)
	_player.damage_taken_from.connect(_hud.show_damage_direction)
	_player.died.connect(_on_player_died)
	_hud.restart_requested.connect(_on_restart)


func _process(delta: float) -> void:
	if not _game_over:
		_elapsed_time += delta


func _on_player_died() -> void:
	_game_over = true
	_hud.show_game_over(_kills, 0, 0)


func _on_restart() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/labyrinth.tscn")
