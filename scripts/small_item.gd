@tool
extends RigidBody3D

@export var item_data: Resource
@export var item_mesh: Mesh:
	set(value):
		item_mesh = value
		atualizar_item()

func _ready() -> void:
	atualizar_item()

func atualizar_item():
	var mesh_instance = get_node_or_null("MeshInstance3D")
	var collision_shape = get_node_or_null("CollisionShape3D")
	
	if mesh_instance:
		mesh_instance.mesh = item_mesh	
	
	if collision_shape:
		if item_mesh != null:
			collision_shape.shape = item_mesh.create_convex_shape()
		else: 
			collision_shape.shape = null
