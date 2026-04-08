extends Area3D

@export var highlight_material: ShaderMaterial

func _on_body_entered(body: Node3D) -> void:
	var interaction_comp = body.get_node_or_null("InteractionComponent")
	
	if interaction_comp and interaction_comp.can_interact:
		if "item_data" in body:
			var mesh_instance = find_mesh_child(body)
			if mesh_instance:
				mesh_instance.material_overlay = highlight_material

func _on_body_exited(body: Node3D) -> void:
	var interaction_comp = body.get_node_or_null("InteractionComponent")
	
	if interaction_comp:
		var mesh_instance = find_mesh_child(body)
		if mesh_instance:
			mesh_instance.material_overlay = null

func find_mesh_child(parent_node: Node) -> MeshInstance3D:
	for child in parent_node.get_children():
		if child is MeshInstance3D:
			return child
	return null
