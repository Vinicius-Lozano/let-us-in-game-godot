extends Node

class_name MovementComponent
@export_category("Component Settings")

@export var target_node: Node3D
@export var start_position: Vector3 = Vector3.ZERO
@export var end_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	if target_node == null:
		target_node = get_parent() as Node3D

	if target_node == null:
		push_error("Missing Target node")

func execute(percentage: float) -> void:
	if target_node == null:
		return
		
	target_node.position = start_position.lerp(end_position, percentage)
