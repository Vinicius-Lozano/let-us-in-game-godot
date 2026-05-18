extends Node

@onready var inventory_controller: Node = $"../InventoryController/CanvasLayer/InventoryUI"
@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = $"../Head/Eyes/Camera3D/InteractionRaycast"
@onready var player_camera: Camera3D = $"../Head/Eyes/Camera3D"
@onready var hand: Marker3D = %Hand
@onready var reticle_nodes: Array = [%DefaultReticle, %HandOpen, %HandClosed]

enum ReticleType {DEFAULT, HAND_OPEN, HAND_CLOSED}

var current_object: Object
var current_reticle: ReticleType
var last_potential_object: Object
var interaction_component: Node


func _process(_delta: float) -> void:
	if current_object:
		handle_active_interactio()
	else:
		handle_raycast_detection()

func handle_active_interactio() -> void:
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
	
	if potential_object and potential_object is Node:
		var node: Node = potential_object
		interaction_component = null
		while node:
			interaction_component = node.get_node_or_null("InteractionComponent")
			if interaction_component:
				break
			node = node.get_parent()
		if interaction_component and interaction_component.can_interact:
			target_reticle = ReticleType.HAND_OPEN
			last_potential_object = current_object
			
			if "item_data" in potential_object and Input.is_action_just_pressed('interact'):
				if inventory_controller.has_free_slot():
					inventory_controller.pickup_item(potential_object.item_data)
					potential_object.queue_free()
					set_reticle(ReticleType.DEFAULT)
					return

			if Input.is_action_just_pressed("hand_primary"):
				current_object = potential_object
				target_reticle = ReticleType.HAND_CLOSED
				
				interaction_component.preInteract(hand, current_object)
				
				if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
					var local_point = current_object.to_local(interaction_raycast.get_collision_point())
					interaction_component.set_direction(local_point)
	set_reticle(target_reticle)

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
