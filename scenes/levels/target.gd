extends StaticBody3D

var _health: int = 30

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	_mesh.set_surface_override_material(0, _mesh.get_surface_override_material(0).duplicate())


func take_damage(amount: int) -> void:
	_health -= amount
	var mat: StandardMaterial3D = _mesh.get_surface_override_material(0)
	mat.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self):
		return
	if _health <= 0:
		queue_free()
	else:
		mat.albedo_color = Color.RED
