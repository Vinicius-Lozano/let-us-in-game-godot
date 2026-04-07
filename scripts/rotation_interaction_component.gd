extends Node

class_name  RotationComponent
@export_category("Component Settings")

@export var target_node: Node3D
@export var start_rotation_degrees: Vector3 = Vector3.ZERO
@export var end_rotation_degrees: Vector3 = Vector3.ZERO

func _ready() -> void:
	if target_node == null:
		target_node = get_parent() as Node3D
	
	if target_node == null:
		push_error("Missing Target node")

func execute(percentage: float) -> void:
	if target_node == null:
		return
	
	var new_rotation: Vector3 = Vector3.ZERO
	new_rotation.x = lerp(start_rotation_degrees.x, end_rotation_degrees.x, percentage)
	new_rotation.y = lerp(start_rotation_degrees.y, end_rotation_degrees.y, percentage)
	new_rotation.z = lerp(start_rotation_degrees.z, end_rotation_degrees.z, percentage)
	
	target_node.rotation_degrees = new_rotation
