extends Area3D

signal picked_up

var _rotation_speed: float = 2.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotation.y += _rotation_speed * delta


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		picked_up.emit()
		queue_free()
