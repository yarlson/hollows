extends CanvasLayer

signal restart_requested

@onready var _health_bar: ProgressBar = $HealthContainer/HBox/HealthBar
@onready var _game_over_panel: PanelContainer = $GameOverPanel
@onready var _restart_button: Button = $GameOverPanel/VBox/RestartButton
@onready var _victory_panel: PanelContainer = $VictoryPanel
@onready var _victory_restart: Button = $VictoryPanel/VBox/RestartButton
@onready var _wave_label: Label = $WaveInfo/WaveLabel
@onready var _enemy_count_label: Label = $WaveInfo/EnemyCountLabel


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)
	_victory_restart.pressed.connect(_on_restart_pressed)
	_game_over_panel.visible = false
	_victory_panel.visible = false


func update_health(new_health: int, max_health: int) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = new_health


func update_wave_info(wave: int, total_waves: int) -> void:
	_wave_label.text = "Wave %d/%d" % [wave, total_waves]


func update_enemy_count(count: int) -> void:
	_enemy_count_label.text = "Enemies: %d" % count


func show_game_over() -> void:
	_game_over_panel.visible = true


func show_victory() -> void:
	_victory_panel.visible = true


func _on_restart_pressed() -> void:
	restart_requested.emit()
