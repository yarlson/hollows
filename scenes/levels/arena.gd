extends Node3D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const WAVE_COUNTS := [3, 4, 5, 6, 8]
const WAVE_DELAY: float = 2.0

var _current_wave: int = 0
var _enemies_alive: int = 0
var _game_over: bool = false
var _spawn_positions: Array[Vector3] = []

@onready var _player: CharacterBody3D = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _wave_timer: Timer = $WaveTimer


func _ready() -> void:
	for child in $SpawnPoints.get_children():
		var sp := child as Node3D
		_spawn_positions.append(sp.global_position)
	_player.health_changed.connect(_hud.update_health)
	_player.hit_landed.connect(_hud.flash_hitmarker)
	_player.damage_taken_from.connect(_hud.show_damage_direction)
	_player.died.connect(_on_player_died)
	_hud.restart_requested.connect(_on_restart)
	_player.add_to_group(&"player")
	_wave_timer.timeout.connect(_on_wave_timer_timeout)
	_start_wave()


func _start_wave() -> void:
	_current_wave += 1
	var count: int = WAVE_COUNTS[_current_wave - 1]
	_enemies_alive = count
	_hud.update_wave_info(_current_wave, WAVE_COUNTS.size())
	_hud.update_enemy_count(_enemies_alive)
	_spawn_enemies(count)


func _spawn_enemies(count: int) -> void:
	var positions := _spawn_positions.duplicate()
	positions.shuffle()
	for i in count:
		var enemy := ENEMY_SCENE.instantiate() as CharacterBody3D
		add_child(enemy)
		enemy.global_position = positions[i % positions.size()]
		enemy.connect(&"died", _on_enemy_died)


func _on_enemy_died() -> void:
	_enemies_alive -= 1
	_hud.update_enemy_count(_enemies_alive)
	if _enemies_alive <= 0 and not _game_over:
		if _current_wave >= WAVE_COUNTS.size():
			_player.set_process_unhandled_input(false)
			_player.set_physics_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_hud.show_victory()
		else:
			_wave_timer.start(WAVE_DELAY)


func _on_player_died() -> void:
	_game_over = true
	_wave_timer.stop()
	_hud.show_game_over()


func _on_wave_timer_timeout() -> void:
	_start_wave()


func _on_restart() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/arena.tscn")
