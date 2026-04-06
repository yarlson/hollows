extends CanvasLayer

signal restart_requested

@onready var _health_bar: ProgressBar = $HealthContainer/HBox/HealthBar
@onready var _game_over_panel: PanelContainer = $GameOverPanel
@onready var _restart_button: Button = $GameOverPanel/VBox/RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)
	_game_over_panel.visible = false


func update_health(new_health: int, max_health: int) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = new_health


func show_game_over() -> void:
	_game_over_panel.visible = true


func _on_restart_pressed() -> void:
	restart_requested.emit()
