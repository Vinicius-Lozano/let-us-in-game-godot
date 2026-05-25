@tool
extends RigidBody3D

@export var item_data: ItemData:
	set(value):
		item_data = value
		if is_node_ready():
			update_item()

func _ready() -> void:
	update_item()

func update_item() -> void:
	var base_mesh_instance = get_node_or_null("MeshInstance3D")
	var base_collision = get_node_or_null("CollisionShape3D")
	
	if item_data == null:
		if base_mesh_instance:
			base_mesh_instance.mesh = null
		return
		
	self.scale = item_data.world_scale
	
	for child in get_children():
		if child.name == "ModelPrefab":
			child.free()
			
	var active_visual_node: Node3D = null
			
	# CENÁRIO A: O item usa um Prefab/GLB (PackedScene)
	if item_data.get("item_model_prefab") != null and item_data.item_model_prefab != null:
		if base_mesh_instance:
			base_mesh_instance.mesh = null 
			
		var new_model = item_data.item_model_prefab.instantiate()
		new_model.name = "ModelPrefab"
		add_child(new_model)
		active_visual_node = new_model
		
		# --- CORRIGIDO: Repassa o Shader de OVERLAY (Brilho) para todos os pedaços do GLB ---
		if base_mesh_instance and base_mesh_instance.material_overlay != null:
			_apply_material_to_hierarchy(new_model, base_mesh_instance.material_overlay)
		
	# CENÁRIO B: O item usa um Mesh simples nativo
	elif item_data.mesh != null:
		if base_mesh_instance:
			base_mesh_instance.mesh = item_data.mesh
			active_visual_node = base_mesh_instance
			
	# CENÁRIO C: Vazio
	else:
		if base_mesh_instance:
			base_mesh_instance.mesh = null
			
	# Geração Automática de Física (AABB)
	if base_collision and active_visual_node:
		_generate_primitive_collision(active_visual_node, base_collision)

# ==========================================
# FUNÇÕES AUXILIARES DE SHADER E FÍSICA
# ==========================================

# Algoritmo Recursivo que acha todas as malhas do GLB e aplica o seu Shader
func _apply_material_to_hierarchy(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = mat # CORRIGIDO: Agora aplica como Overlay (por cima)
	for child in node.get_children():
		_apply_material_to_hierarchy(child, mat)

func _generate_primitive_collision(visual_node: Node3D, col_node: CollisionShape3D) -> void:
	var bounds: AABB = _calculate_bounds(visual_node)
	
	var box_shape = BoxShape3D.new()
	box_shape.size = bounds.size * 1.05 
	
	col_node.shape = box_shape
	col_node.position = bounds.position + (bounds.size / 2.0)

# Algoritmo Matemático Preciso (Leva em conta Escala e Rotação dentro do GLB)
func _calculate_bounds(root_node: Node3D) -> AABB:
	var aabb = AABB()
	var has_bounds = false
	var meshes: Array[VisualInstance3D] = []
	
	# Puxa todos os nós visuais de dentro da hierarquia
	_find_visual_instances(root_node, meshes)
	
	for vi in meshes:
		# Pega a transformação exata da malha em relação à raiz do prefab
		var rel_transform = root_node.global_transform.affine_inverse() * vi.global_transform
		var local_aabb = vi.get_aabb()
		
		# A mágica do Godot 4: Multiplicar Transform3D por AABB ajusta a escala e rotação!
		var transformed_aabb = rel_transform * local_aabb
		
		if not has_bounds:
			aabb = transformed_aabb
			has_bounds = true
		else:
			aabb = aabb.merge(transformed_aabb)
			
	# Prevenção contra GLBs vazios ou corrompidos
	if not has_bounds:
		return AABB(Vector3(-0.1, -0.1, -0.1), Vector3(0.2, 0.2, 0.2))
		
	return aabb

# Caçador de malhas
func _find_visual_instances(current_node: Node, result: Array[VisualInstance3D]) -> void:
	if current_node is VisualInstance3D:
		result.append(current_node)
	for child in current_node.get_children():
		_find_visual_instances(child, result)
