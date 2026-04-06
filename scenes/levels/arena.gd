extends Node3D

@onready var _player: CharacterBody3D = $Player
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	_player.health_changed.connect(_hud.update_health)
	_player.died.connect(_hud.show_game_over)
	_hud.restart_requested.connect(_on_restart)
	_player.add_to_group(&"player")


func _on_restart() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/arena.tscn")
