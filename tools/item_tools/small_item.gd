@tool
extends RigidBody3D

@export var item_data: ItemData:
	set(value):
		item_data = value
		# A MÁGICA: Só roda a atualização se o nó e seus filhos já existirem
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
		
	# CENÁRIO B: O item usa um Mesh simples nativo
	elif item_data.mesh != null:
		if base_mesh_instance:
			base_mesh_instance.mesh = item_data.mesh
			active_visual_node = base_mesh_instance
			
	# CENÁRIO C: Vazio
	else:
		if base_mesh_instance:
			base_mesh_instance.mesh = null
			
	# ==========================================
	# NOVO: Geração Automática de Física (AABB)
	# ==========================================
	if base_collision and active_visual_node:
		_generate_primitive_collision(active_visual_node, base_collision)

# ==========================================
# FUNÇÕES AUXILIARES DE FÍSICA
# ==========================================

func _generate_primitive_collision(visual_node: Node3D, col_node: CollisionShape3D) -> void:
	# 1. Mede o tamanho real do modelo 3D (Mesh ou Prefab)
	var bounds: AABB = _calculate_bounds(visual_node)
	
	# 2. Cria uma primitiva leve (O(1) para física)
	var box_shape = BoxShape3D.new()
	
	# 3. Ajusta o tamanho da caixa para as medidas exatas do objeto
	# Multiplicamos por 1.05 (margem de 5%) para evitar que o modelo atravesse o chão
	box_shape.size = bounds.size * 1.05 
	
	col_node.shape = box_shape
	
	# 4. Ajusta o "Pivô" da colisão para ficar no meio geométrico do objeto
	col_node.position = bounds.position + (bounds.size / 2.0)

# Algoritmo Recursivo para encontrar o tamanho de qualquer objeto (até se tiver várias partes)
func _calculate_bounds(node: Node3D) -> AABB:
	var aabb = AABB()
	var has_bounds = false
	
	# Se for uma malha renderizável, pegamos a "caixa" dela
	if node is VisualInstance3D:
		aabb = node.get_aabb()
		has_bounds = true
		
	# Checamos os filhos (caso seja um Prefab GLB composto de várias partes)
	for child in node.get_children():
		if child is Node3D:
			var child_aabb = _calculate_bounds(child)
			
			# Translada a caixa do filho para o mundo do pai
			var transformed_aabb = AABB(child.position + child_aabb.position, child_aabb.size)
			
			if not has_bounds:
				aabb = transformed_aabb
				has_bounds = true
			else:
				# Funde as caixas para criar uma caixa maior que englobe tudo
				aabb = aabb.merge(transformed_aabb)
				
	return aabb
