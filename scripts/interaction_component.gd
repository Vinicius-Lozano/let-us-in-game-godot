extends Node

enum InteractionType {
	DEFAULT,
	DOOR,
	SWITCH,
	WHEEL,
	KEYPAD,
	COLLECT
}

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT
@export var maximum_rotation: float = 90
@export var pivot_point: Node3D
@export var nodes_to_effect: Array[Node]
@export var is_locked: bool = false

var can_interact: bool = true
var is_interacting: bool = false
var player_hand: Marker3D
var lock_camera: bool = false
var starting_rotation: float
var is_front: bool
var current_angle: float = 0.0
var initial_transform: Transform3D
var was_just_unlocked: bool = false

# Door feedback
var rattle_tween: Tween

# Keypad
var buttons: Array[StaticBody3D]
var entered_code: Array[int]
@export var correct_code: Array[int] = [1,2,3,4,5]
var max_code_length: int = 5
var screen_label: Label3D

func _ready() -> void:
	match interaction_type:
		InteractionType.DOOR:
			starting_rotation = pivot_point.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation) + maximum_rotation)
		InteractionType.SWITCH:
			initial_transform = object_ref.transform
			maximum_rotation = deg_to_rad(maximum_rotation)
		InteractionType.WHEEL:
			initial_transform = object_ref.transform
			maximum_rotation = deg_to_rad(maximum_rotation)
			current_angle = 0.0
		InteractionType.KEYPAD:
			screen_label = get_parent().get_node_or_null("%Screen")
			for node in get_parent().get_children():
				if node is StaticBody3D:
					buttons.append(node)

func preInteract(hand: Marker3D, target: Node = null) -> void:
	is_interacting = true
	match interaction_type:
		InteractionType.DEFAULT:
			player_hand = hand
		InteractionType.DOOR:
			lock_camera = true
		InteractionType.SWITCH:
			lock_camera = true
		InteractionType.WHEEL:
			lock_camera = true
		InteractionType.KEYPAD:
			_press_button(target)

func interact() -> void:
	if not can_interact:
		return
	match interaction_type:
		InteractionType.DEFAULT:
			_default_interact()
		InteractionType.COLLECT: 
			# Tenta rodar a função do Puzzle de Números
			if get_parent().has_method("collect_piece"):
				get_parent().collect_piece()
			# Tenta rodar a função das Notas de Lore que criamos!
			elif get_parent().has_method("read_note"):
				get_parent().read_note()

func auxInteract() -> void:
	if not can_interact:
		return
	match interaction_type:
		InteractionType.DEFAULT:
			_default_throw()

func postInteract() -> void:
	is_interacting = false
	lock_camera = false

func _input(event: InputEvent) -> void:
	if is_interacting:
		match interaction_type:
			InteractionType.DOOR:
				if event is InputEventMouseMotion:
					if is_locked:
						# Rattle the door if the player tries to move it while locked
						_rattle_door()
					else:
						# Normal door opening logic
						if is_front:
							pivot_point.rotate_y(-event.relative.y * .001)
						else:
							pivot_point.rotate_y(event.relative.y * .001)
						
						pivot_point.rotation.y = clamp(pivot_point.rotation.y, starting_rotation, maximum_rotation)
			
			InteractionType.SWITCH:
				if event is InputEventMouseMotion:
					var percentage: float
					current_angle -= event.relative.y * .001
					current_angle = clamp(current_angle, 0.0, maximum_rotation)
					
					object_ref.transform = initial_transform
					object_ref.rotate_object_local(Vector3.RIGHT, current_angle)
					
					percentage = inverse_lerp(0.0, maximum_rotation, current_angle)
					notify_nodes(percentage)
			
			InteractionType.WHEEL:
				if event is InputEventMouseMotion:
					var rotation_speed: float = 0.0001
					var input_movement = event.relative.x * rotation_speed
					
					current_angle += input_movement
					current_angle = clamp(current_angle, 0.0, maximum_rotation)
					
					object_ref.transform = initial_transform
					object_ref.rotate_object_local(Vector3.LEFT, current_angle)
					
					var percentage: float = inverse_lerp(0.0, maximum_rotation, current_angle)
					notify_nodes(percentage)

func _default_interact() -> void:
	if object_ref == null or player_hand == null:
		return
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		rigid_body_3d.set_linear_velocity((object_distance) * (5/rigid_body_3d.mass))

func _default_throw() -> void:
	if object_ref == null or player_hand == null:
		return
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		var throw_direction: Vector3 = -player_hand.global_transform.basis.z.normalized()
		var throw_strength: float = (20.0/rigid_body_3d.mass)
		rigid_body_3d.set_axis_velocity(throw_direction * throw_strength)
		
		can_interact = false
		await get_tree().create_timer(2.0).timeout
		can_interact = true

func set_direction(_normal: Vector3) -> void:
	if _normal.z > 0:
		is_front = true
	else:
		is_front = false

func _press_button(target: Node) -> void:
	if target == null:
		return
		
	if target in buttons:
		var tween := create_tween()
		tween.tween_property(target, "position:z", 0.02, 0.1)
		tween.tween_property(target, "position:z", 0.0, 0.1)
	
	match target.name:
		"SBCL":
			entered_code.clear()
			screen_label.text = ""
			screen_label.modulate = Color.WHITE
		"SBOK":
			if entered_code == correct_code:
				screen_label.text = "ENTER"
				screen_label.modulate = Color.GREEN
				
				# Iterate through all linked nodes (like the Door) and unlock them
				for node in nodes_to_effect:
					if node and node.has_method("unlock"):
						node.call("unlock")
			else:
				screen_label.text = "ERROR"
				screen_label.modulate = Color.RED
				
			entered_code.clear()
			
		_:
			var num = str(target.name).substr(2).to_int()
			if entered_code.size() < max_code_length:
				entered_code.append(num)
				var text: String = ""
				for n in entered_code:
					text += str(n)
				screen_label.text = text
				screen_label.modulate = Color.WHITE
			else:
				print("Code is Full")

func notify_nodes(percentage: float) -> void:
	for node in nodes_to_effect:
		if node.has_method("execute"):
			node.call("execute", percentage)

# --- NEW FUNCTIONS ---

func unlock() -> void:
	# Changes the state of the component so the door can be opened
	is_locked = false
	was_just_unlocked = true
	print("Door Unlocked!")

func _rattle_door() -> void:
	# Prevents creating multiple Tweens if the player moves the mouse wildly
	if rattle_tween and rattle_tween.is_valid():
		return 
		
	rattle_tween = create_tween()
	var original_rot_y = pivot_point.rotation.y
	var rattle_amount = deg_to_rad(2.0) # Adjustable variable: controls how intense the shake is

	# Creates a sequence of small rotations to simulate the "shake"
	rattle_tween.tween_property(pivot_point, "rotation:y", original_rot_y + rattle_amount, 0.05)
	rattle_tween.tween_property(pivot_point, "rotation:y", original_rot_y - rattle_amount, 0.05)
	rattle_tween.tween_property(pivot_point, "rotation:y", original_rot_y + rattle_amount, 0.05)
	rattle_tween.tween_property(pivot_point, "rotation:y", original_rot_y, 0.05)
