@tool
extends RigidBody3D

@export var item_data: ItemData:
	set(value):
		item_data = value
		update_item()

func _ready() -> void:
	update_item()

func update_item():
	var mesh_instance = get_node_or_null("MeshInstance3D")
	var collision_shape = get_node_or_null("CollisionShape3D")
	
	if item_data == null:
		return
	
	if mesh_instance:
		mesh_instance.mesh = item_data.mesh
	
	if collision_shape:
		if item_data.mesh != null:
			collision_shape.shape = item_data.mesh.create_convex_shape()
		else: 
			collision_shape.shape = null
