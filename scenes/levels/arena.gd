extends Node3D

@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	# CSG shapes need several frames to generate mesh/collision data
	for i in 3:
		await get_tree().physics_frame
	_nav_region.bake_navigation_mesh()
