extends Node3D

const ENEMY_STANDARD: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ENEMY_RUNNER: PackedScene = preload("res://scenes/enemies/enemy_runner.tscn")
const ENEMY_BRUTE: PackedScene = preload("res://scenes/enemies/enemy_brute.tscn")
const WAVES: Array[Dictionary] = [
	{&"standard": 3},
	{&"standard": 2, &"runner": 2},
	{&"standard": 3, &"runner": 2},
	{&"standard": 2, &"runner": 2, &"brute": 2},
	{&"standard": 2, &"runner": 3, &"brute": 3},
]
const HEALTH_PICKUP: PackedScene = preload("res://scenes/pickups/health_pickup.tscn")
const WAVE_DELAY: float = 2.0

var _current_wave: int = 0
var _enemies_alive: int = 0
var _kills: int = 0
var _elapsed_time: float = 0.0
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


func _process(delta: float) -> void:
	if not _game_over:
		_elapsed_time += delta


func _start_wave() -> void:
	_current_wave += 1
	var wave_def: Dictionary = WAVES[_current_wave - 1]
	var count: int = 0
	for type_name: StringName in wave_def:
		count += wave_def[type_name] as int
	_enemies_alive = count
	_hud.update_wave_info(_current_wave, WAVES.size())
	_hud.update_enemy_count(_enemies_alive)
	_spawn_enemies(wave_def)


func _spawn_enemies(wave_def: Dictionary) -> void:
	var scene_map := {
		&"standard": ENEMY_STANDARD,
		&"runner": ENEMY_RUNNER,
		&"brute": ENEMY_BRUTE,
	}
	var to_spawn: Array[PackedScene] = []
	for type_name: StringName in wave_def:
		var scene: PackedScene = scene_map[type_name]
		for i in wave_def[type_name] as int:
			to_spawn.append(scene)
	var positions := _spawn_positions.duplicate()
	positions.shuffle()
	for i in to_spawn.size():
		var enemy := to_spawn[i].instantiate() as CharacterBody3D
		add_child(enemy)
		enemy.global_position = positions[i % positions.size()]
		enemy.connect(&"died", _on_enemy_died)


func _spawn_pickups() -> void:
	var positions := _spawn_positions.duplicate()
	positions.shuffle()
	var count: int = 1 if _current_wave <= 2 else 2
	for i in count:
		var pickup := HEALTH_PICKUP.instantiate()
		add_child(pickup)
		pickup.global_position = positions[i] + Vector3(0.0, 0.5, 0.0)
		pickup.add_to_group(&"pickups")


func _on_enemy_died() -> void:
	_enemies_alive -= 1
	_kills += 1
	_hud.update_kills(_kills)
	_hud.update_enemy_count(_enemies_alive)
	if _enemies_alive <= 0 and not _game_over:
		if _current_wave >= WAVES.size():
			_game_over = true
			_player.set_process_unhandled_input(false)
			_player.set_physics_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_hud.show_victory(_kills, _elapsed_time)
		else:
			_spawn_pickups()
			_wave_timer.start(WAVE_DELAY)


func _on_player_died() -> void:
	_game_over = true
	_wave_timer.stop()
	_hud.show_game_over(_kills, _current_wave, WAVES.size())


func _on_wave_timer_timeout() -> void:
	_start_wave()


func _on_restart() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/arena.tscn")
