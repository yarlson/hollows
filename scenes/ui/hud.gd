extends CanvasLayer

signal restart_requested

const CROSSHAIR_COLOR := Color(0.2, 1.0, 0.2, 0.9)
const HEALTH_COLOR_HIGH := Color(0.2, 0.8, 0.2)
const HEALTH_COLOR_MID := Color(0.9, 0.8, 0.1)
const HEALTH_COLOR_LOW := Color(0.9, 0.1, 0.1)
const HEALTH_THRESHOLD_MID: float = 0.5
const HEALTH_THRESHOLD_LOW: float = 0.25

var _damage_indicator_count: int = 0
var _health_fill_style: StyleBoxFlat = null

@onready var _health_bar: ProgressBar = $HealthContainer/HBox/HealthBar
@onready var _crosshair_top: ColorRect = $Crosshair/Top
@onready var _crosshair_bottom: ColorRect = $Crosshair/Bottom
@onready var _crosshair_left: ColorRect = $Crosshair/Left
@onready var _crosshair_right: ColorRect = $Crosshair/Right
@onready var _game_over_panel: PanelContainer = $GameOverPanel
@onready var _restart_button: Button = $GameOverPanel/VBox/RestartButton
@onready var _victory_panel: PanelContainer = $VictoryPanel
@onready var _victory_restart: Button = $VictoryPanel/VBox/RestartButton
@onready var _kills_label: Label = $KillsLabel
@onready var _game_over_summary: Label = $GameOverPanel/VBox/SummaryLabel
@onready var _victory_summary: Label = $VictoryPanel/VBox/SummaryLabel
@onready var _key_status: Label = $KeyStatus
@onready var _level_label: Label = $LevelLabel
@onready var _level_announcement: Label = $LevelAnnouncement
@onready var _damage_top: ColorRect = $DamageIndicators/Top
@onready var _damage_bottom: ColorRect = $DamageIndicators/Bottom
@onready var _damage_left: ColorRect = $DamageIndicators/Left
@onready var _damage_right: ColorRect = $DamageIndicators/Right


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)
	_victory_restart.pressed.connect(_on_restart_pressed)
	_game_over_panel.visible = false
	_victory_panel.visible = false
	_level_announcement.visible = false
	_health_fill_style = StyleBoxFlat.new()
	_health_fill_style.bg_color = HEALTH_COLOR_HIGH
	_health_bar.add_theme_stylebox_override(&"fill", _health_fill_style)


func update_health(new_health: int, max_health: int) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = new_health
	if _health_fill_style:
		var ratio := float(new_health) / float(max_health) if max_health > 0 else 0.0
		if ratio <= HEALTH_THRESHOLD_LOW:
			_health_fill_style.bg_color = HEALTH_COLOR_LOW
		elif ratio <= HEALTH_THRESHOLD_MID:
			_health_fill_style.bg_color = HEALTH_COLOR_MID
		else:
			_health_fill_style.bg_color = HEALTH_COLOR_HIGH


func update_kills(kills: int) -> void:
	_kills_label.text = "Kills: %d" % kills


func update_key_status(has_key: bool) -> void:
	_key_status.text = "KEY: FOUND" if has_key else "KEY: ---"


func update_level(level_number: int) -> void:
	_level_label.text = "Level %d" % level_number


func flash_level_announcement(level_number: int) -> void:
	_level_announcement.text = "- Level %d -" % level_number
	_level_announcement.visible = true
	_level_announcement.modulate.a = 1.0
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self):
		return
	var tween := create_tween()
	tween.tween_property(_level_announcement, "modulate:a", 0.0, 0.8)
	await tween.finished
	if is_instance_valid(self):
		_level_announcement.visible = false


func show_game_over(kills: int, time_seconds: float, level: int) -> void:
	@warning_ignore("integer_division")
	var mins := int(time_seconds) / 60
	var secs := int(time_seconds) % 60
	_game_over_summary.text = (
		"Level %d  |  Kills: %d  |  Time: %d:%02d" % [level, kills, mins, secs]
	)
	_game_over_panel.visible = true


func show_victory(kills: int, time_seconds: float, total_levels: int) -> void:
	@warning_ignore("integer_division")
	var mins := int(time_seconds) / 60
	var secs := int(time_seconds) % 60
	_victory_summary.text = (
		"%d Levels  |  Kills: %d  |  Time: %d:%02d" % [total_levels, kills, mins, secs]
	)
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


func flash_key_status() -> void:
	_key_status.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.2))
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self):
		return
	_key_status.remove_theme_color_override(&"font_color")


func show_damage_direction(angle: float) -> void:
	if angle > -PI / 4.0 and angle < PI / 4.0:
		_damage_top.visible = true
	elif angle >= PI / 4.0 and angle < 3.0 * PI / 4.0:
		_damage_right.visible = true
	elif angle <= -PI / 4.0 and angle > -3.0 * PI / 4.0:
		_damage_left.visible = true
	else:
		_damage_bottom.visible = true
	_damage_indicator_count += 1
	var my_count := _damage_indicator_count
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self):
		return
	if _damage_indicator_count == my_count:
		_damage_top.visible = false
		_damage_bottom.visible = false
		_damage_left.visible = false
		_damage_right.visible = false


func _on_restart_pressed() -> void:
	restart_requested.emit()
