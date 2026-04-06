extends Area3D

signal picked_up

@export var heal_amount: int = 25

var _rotation_speed: float = 2.0


func _process(delta: float) -> void:
	rotation.y += _rotation_speed * delta


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method(&"heal"):
		body.heal(heal_amount)
		picked_up.emit()
		queue_free()
