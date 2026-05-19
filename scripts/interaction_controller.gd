extends Node

@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = $"../Head/Eyes/Camera3D/InteractionRaycast"
@onready var player_camera: Camera3D = $"../Head/Eyes/Camera3D"

@export var base_item_prefab: PackedScene
@export var sanity_controller: Node

@onready var weapon_pivot: Node3D = $"../Head/Eyes/Camera3D/WeaponPivot" 
@onready var physics_hand: Marker3D = %Hand 
@onready var held_item_marker: Marker3D = %HeldItem 

@onready var reticle_nodes: Array = [%DefaultReticle, %HandOpen, %HandClosed]

enum ReticleType {DEFAULT, HAND_OPEN, HAND_CLOSED}

var current_object: Object
var current_reticle: ReticleType
var last_potential_object: Object
var interaction_component: Node

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
		if "item_data" in potential_object and potential_object.item_data != null:
			is_looking_at_interactable = true
			target_reticle = ReticleType.HAND_OPEN
			
			if Input.is_action_just_pressed('interact'):
				equip_item(potential_object.item_data)
				potential_object.queue_free()
				set_reticle(ReticleType.DEFAULT)
				return

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
				interaction_component.preInteract(physics_hand, current_object)
				
				if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
					var local_point = current_object.to_local(interaction_raycast.get_collision_point())
					interaction_component.set_direction(local_point)
					
	set_reticle(target_reticle)
	
	if not is_looking_at_interactable and Input.is_action_just_pressed('interact'):
		use_held_item()

func handle_item_drop() -> void:
	if Input.is_action_just_pressed("drop_item"):
		drop_item()

func equip_item(new_item_data: ItemData) -> void:
	if held_item_data != null:
		drop_item()
		
	held_item_data = new_item_data
	
	# Validação Orientada a Dados: É uma arma?
	if is_weapon(held_item_data):
		if weapon_pivot and weapon_pivot.has_method("equip"):
			weapon_pivot.equip()
	else:
		var visual_mesh = MeshInstance3D.new()
		visual_mesh.mesh = held_item_data.mesh
		held_item_marker.add_child(visual_mesh)
		visual_mesh.position = Vector3.ZERO
		held_item_instance = visual_mesh

func use_held_item() -> void:
	if held_item_data == null or held_item_data.action_data == null:
		return
		
	var action = held_item_data.action_data
	
	match action.action_type:
		ActionData.ActionType.CONSUMABLE:
			var consumable = action as ConsumableAction
			if consumable.modifier_name == 'sanity' and sanity_controller != null:
				sanity_controller.add_sanity(consumable.modifier_value)
			clear_held_item()
			
		ActionData.ActionType.INSPECTABLE:
			print("Inspecionando: ", held_item_data.name)
			
		ActionData.ActionType.EQUIPPABLE:
			var equippable = action as EquippableAction
			print(equippable.success_text)
			
		ActionData.ActionType.WEAPON:
			# O ataque é controlado pela action "atacar" no próprio script da arma.
			# Aqui podemos colocar algo extra se o jogador apertar "E" segurando a arma (ex: inspecionar).
			pass

func drop_item() -> void:
	if held_item_data == null:
		return

	if base_item_prefab == null:
		return

	var drop_instance = base_item_prefab.instantiate() as RigidBody3D
	if drop_instance:
		get_tree().current_scene.add_child(drop_instance)
		
		if "world_scale" in held_item_data:
			drop_instance.scale = held_item_data.world_scale
			
		drop_instance.item_data = held_item_data 

		var drop_distance: float = 1.5
		var forward_dir: Vector3 = -player_camera.global_transform.basis.z.normalized()
		var new_position: Vector3 = player_camera.global_position + (forward_dir * drop_distance)
		new_position.y = 1.80 

		drop_instance.global_position = new_position
		drop_instance.linear_velocity = Vector3.ZERO

	clear_held_item()

func clear_held_item() -> void:
	if weapon_pivot and weapon_pivot.has_method("unequip"):
		weapon_pivot.unequip()
	
	if held_item_instance:
		held_item_instance.queue_free()
	
	held_item_instance = null
	held_item_data = null

# Função auxiliar para manter o Clean Code
func is_weapon(item: ItemData) -> bool:
	return item.action_data != null and item.action_data.action_type == ActionData.ActionType.WEAPON

# Funções de retícula e câmera omitidas para brevidade (mantém-se exatamente iguais)
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
