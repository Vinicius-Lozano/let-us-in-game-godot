extends Control

const SMALL_ITEM = preload("uid://wgjymdinw7jw")
@onready var player: CharacterBody3D = $"../../player"


func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var node = SMALL_ITEM.instantiate()
	
	node.item_data = data.item
	
	get_tree().current_scene.add_child(node)
	data.item = null
	data.update_ui()
	node.global_position = player.global_position + (-player.global_transform.basis.z * 1 ) + Vector3(0, 1, 0)
