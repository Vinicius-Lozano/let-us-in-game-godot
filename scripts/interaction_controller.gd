extends Node

@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = $"../Head/Eyes/Camera3D/InteractionRaycast"
@onready var player_camera: Camera3D = $"../Head/Eyes/Camera3D"
@export var base_item_prefab: PackedScene
@export var sanity_controller: Node

# Mão Física: Usada para ancorar objetos do mundo (Portas, Caixas)
@onready var physics_hand: Marker3D = %Hand 
# Mão de Inventário: Usada para renderizar o item coletado na tela
@onready var held_item_marker: Marker3D = %HeldItem 

@onready var reticle_nodes: Array = [%DefaultReticle, %HandOpen, %HandClosed]

enum ReticleType {DEFAULT, HAND_OPEN, HAND_CLOSED}

# --- ESTADO DE INTERAÇÃO FÍSICA ---
var current_object: Object
var current_reticle: ReticleType
var last_potential_object: Object
var interaction_component: Node

# --- ESTADO DO ITEM EQUIPADO ---
var held_item_data: ItemData = null
var held_item_instance: MeshInstance3D = null

func _process(_delta: float) -> void:
	if current_object:
		handle_active_interaction()
	else:
		handle_raycast_detection()
		handle_item_drop()

func handle_active_interaction() -> void:
	if not interaction_component:
		current_object = null
		return
	
	if Input.is_action_just_pressed("hand_secondary"):
		interaction_component.auxInteract()
		current_object = null
	elif Input.is_action_pressed("hand_primary"):
		interaction_component.interact()
	else:
		interaction_component.postInteract()
		current_object = null

func handle_raycast_detection() -> void:
	var potential_object = interaction_raycast.get_collider()
	var target_reticle: ReticleType = ReticleType.DEFAULT
	var is_looking_at_interactable: bool = false
	
	if potential_object and potential_object is Node:
		# 1. Checa se o objeto é um Item Coletável
		if "item_data" in potential_object and potential_object.item_data != null:
			is_looking_at_interactable = true
			target_reticle = ReticleType.HAND_OPEN
			
			if Input.is_action_just_pressed('interact'):
				equip_item(potential_object.item_data)
				potential_object.queue_free()
				set_reticle(ReticleType.DEFAULT)
				return

		# 2. Checa se o objeto possui um InteractionComponent (Portas, etc)
		var node: Node = potential_object
		interaction_component = null
		while node:
			interaction_component = node.get_node_or_null("InteractionComponent")
			if interaction_component:
				break
			node = node.get_parent()
			
		if interaction_component and interaction_component.can_interact:
			is_looking_at_interactable = true
			target_reticle = ReticleType.HAND_OPEN
			last_potential_object = current_object
			
			if Input.is_action_just_pressed("hand_primary"):
				current_object = potential_object
				target_reticle = ReticleType.HAND_CLOSED
				
				# Usa a physics_hand para a manipulação do mundo
				interaction_component.preInteract(physics_hand, current_object)
				
				if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
					var local_point = current_object.to_local(interaction_raycast.get_collision_point())
					interaction_component.set_direction(local_point)
					
	set_reticle(target_reticle)
	
	# 3. Lógica Contextual: Se NÃO estiver olhando para nada interativo e apertar "E", usa o item.
	if not is_looking_at_interactable and Input.is_action_just_pressed('interact'):
		use_held_item()

func handle_item_drop() -> void:
	# Registre "drop_item" no Input Map (ex: tecla G ou Q)
	if Input.is_action_just_pressed("drop_item"):
		drop_item()

# ==========================================
# GERENCIAMENTO DO ITEM EQUIPADO
# ==========================================

func equip_item(new_item_data: ItemData) -> void:
	# Se o player já tem um item, joga no chão primeiro
	if held_item_data != null:
		drop_item()
		
	held_item_data = new_item_data
	
	# Cria a representação visual no marker da câmera
	var visual_mesh = MeshInstance3D.new()
	visual_mesh.mesh = held_item_data.mesh
	held_item_marker.add_child(visual_mesh)
	visual_mesh.position = Vector3.ZERO
	held_item_instance = visual_mesh

func use_held_item() -> void:
	if held_item_data == null or held_item_data.action_data == null:
		return
		
	var action = held_item_data.action_data
	
	# Utilizamos o Match com o Enum definido no seu ActionData
	match action.action_type:
		ActionData.ActionType.CONSUMABLE:
			var consumable = action as ConsumableAction

		# Verifica se o modificador é de sanidade
			if consumable.modifier_name == 'sanity':

		# Programação Defensiva: Verifica se o controller foi plugado
				if sanity_controller != null:
		# Agora sim, chamamos a função real do script que você me enviou!
					sanity_controller.add_sanity(consumable.modifier_value)
					print("[DEBUG] Sanidade restaurada em: ", consumable.modifier_value)
				else:
					print("[ERRO] O SanityController não foi arrastado para o Inspector do InteractionController!")

		# Limpa o item da mão após consumir
			clear_held_item()
			
		ActionData.ActionType.INSPECTABLE:
			print("Inspecionando: ", held_item_data.name)
			# Aqui você pode chamar um evento para abrir a tela de inspeção 3D
			
		ActionData.ActionType.EQUIPPABLE:
			var equippable = action as EquippableAction
			print(equippable.success_text)
			if equippable.one_time_use:
				clear_held_item()

func drop_item() -> void:
	if held_item_data == null:
		return

	# Verificação de segurança (Fail-Fast)
	if base_item_prefab == null:
		print("[ERRO] A cena base do item não foi definida! Arraste o 'small_item.tscn' para o campo Base Item Prefab no Inspector do seu Controller.")
		return

	# 1. Instanciamos a "casca" genérica do seu framework
	var drop_instance = base_item_prefab.instantiate() as RigidBody3D

	if drop_instance:
	# 2. Adicionamos a casca ao mundo
		get_tree().current_scene.add_child(drop_instance)

	# 3. Injetamos a "alma" (Os dados do item). 
	# Isso ativa o seu script @tool automaticamente para criar a Mesh e a Colisão!
		drop_instance.item_data = held_item_data 

	# 4. Cálculo de posicionamento
		var drop_distance: float = 1.5
		var forward_dir: Vector3 = -player_camera.global_transform.basis.z.normalized()
		var new_position: Vector3 = player_camera.global_position + (forward_dir * drop_distance)

	# Sua regra de altura estrita
		new_position.y = 1.80 

	# 5. Aplica a posição e zera a velocidade residual
		drop_instance.global_position = new_position
		drop_instance.linear_velocity = Vector3.ZERO

	# Limpamos a mão visual do jogador
	clear_held_item()

func clear_held_item() -> void:
	if held_item_instance:
		held_item_instance.queue_free()
	held_item_instance = null
	held_item_data = null

func isCameraLocked() -> bool:
	return interaction_component != null and interaction_component.lock_camera and interaction_component.is_interacting

func set_reticle(reticle_type: ReticleType) -> void:
	if current_reticle == reticle_type:
		return
	current_reticle = reticle_type
	for r in reticle_nodes:
		r.visible = false
	match current_reticle:
		ReticleType.DEFAULT:
			%DefaultReticle.visible = true
		ReticleType.HAND_OPEN:
			%HandOpen.visible = true
		ReticleType.HAND_CLOSED:
			%HandClosed.visible = true
