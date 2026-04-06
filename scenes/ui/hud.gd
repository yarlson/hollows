extends CanvasLayer

signal restart_requested

const CROSSHAIR_COLOR := Color(0.2, 1.0, 0.2, 0.9)

@onready var _health_bar: ProgressBar = $HealthContainer/HBox/HealthBar
@onready var _crosshair_top: ColorRect = $Crosshair/Top
@onready var _crosshair_bottom: ColorRect = $Crosshair/Bottom
@onready var _crosshair_left: ColorRect = $Crosshair/Left
@onready var _crosshair_right: ColorRect = $Crosshair/Right
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


func flash_hitmarker() -> void:
	_crosshair_top.color = Color.WHITE
	_crosshair_bottom.color = Color.WHITE
	_crosshair_left.color = Color.WHITE
	_crosshair_right.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(self):
		return
	_crosshair_top.color = CROSSHAIR_COLOR
	_crosshair_bottom.color = CROSSHAIR_COLOR
	_crosshair_left.color = CROSSHAIR_COLOR
	_crosshair_right.color = CROSSHAIR_COLOR


func _on_restart_pressed() -> void:
	restart_requested.emit()
