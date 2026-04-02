extends CharacterBody3D

@onready var inventory_controller: InventoryController = $InventoryController/CanvasLayer/InventoryUI

@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera_3d: Camera3D = $Head/Eyes/Camera3D
@onready var ray_cast_3d: RayCast3D = $Head/Eyes/Camera3D/RayCast3D
@onready var standing: CollisionShape3D = $Standing
@onready var crouching: CollisionShape3D = $Crouching
@onready var standup_check: RayCast3D = $StandupCheck


const WALKING_SPEED: float = 3.0
const SPRINTING_SPEED: float = 5.0
const CROUCHING_SPEED: float = 1.0
const CROUCHING_DEPTH: float = -0.9
const JUMP_VELOCITY: float = 4.0

var current_speed: float = 0.0
var moving: bool = false
var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO
var lerp_speed: float = 10.0

# Player Settings
var base_fov: float = 90
var mouse_sensitivty: float = 0.08

enum PlayerState {
	IDLE_STAND,
	IDLE_CROUCH,
	CROUCHING,
	WALKING,
	SPRINTING,
	AIR
	}
var player_state: PlayerState = PlayerState.IDLE_STAND

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('quit'):
		get_tree().quit()
	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * mouse_sensitivty)
		head.rotate_x(deg_to_rad(-event.relative.y) * mouse_sensitivty)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
	
	updatePlayerState()
	updateCamera(delta)
	
	# Up and Down movement
	if not is_on_floor():
		if velocity.y >= 0:
			velocity += get_gravity() * delta
		else:
			velocity += get_gravity() * delta * 2.0
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	
	# Horizontal Movement
	input_dir = Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * 10.0)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	# object Picking
	var focus_object = ray_cast_3d.get_collider()

	if focus_object != null and 'item_data' in focus_object:
		if Input.is_action_just_pressed('interact'):
			
			# 1. Pergunta ao NOVO controller se tem espaço
			if inventory_controller.has_free_slot():
				
				# 2. Manda o controller pegar o item
				inventory_controller.pickup_item(focus_object.item_data)
				
				# 3. Destrói o item 3D do chão
				focus_object.queue_free()
				print("Item coletado com sucesso!")
			else:
				print("Inventário Cheio!")
	move_and_slide()

func updatePlayerState() -> void:
	moving = (input_dir != Vector2.ZERO)
	if not is_on_floor():
		player_state = PlayerState.AIR
	else:
		if Input.is_action_pressed("crouch"):
			if not moving:
				player_state = PlayerState.IDLE_CROUCH
			else:
				player_state = PlayerState.CROUCHING
		elif !standup_check.is_colliding():
			if not moving:
				player_state = PlayerState.IDLE_STAND
			elif Input.is_action_pressed("sprint"):
				player_state = PlayerState.SPRINTING
			else: 
				player_state = PlayerState.WALKING
	
	updatePlayerColShape(player_state)
	updatePlayerSpeed(player_state)

func updatePlayerColShape(_player_state: PlayerState) -> void:
	if _player_state == PlayerState.CROUCHING or _player_state == PlayerState.IDLE_CROUCH:
		standing.disabled = true
		crouching.disabled = false
	else:
		standing.disabled = false
		crouching.disabled = true


func updatePlayerSpeed(_player_state: PlayerState) -> void:
	if _player_state == PlayerState.CROUCHING or _player_state == PlayerState.IDLE_CROUCH:
		current_speed = CROUCHING_SPEED
	elif _player_state == PlayerState.WALKING:
		current_speed = WALKING_SPEED
	elif _player_state == PlayerState.SPRINTING:
		current_speed = SPRINTING_SPEED

func updateCamera(delta: float) -> void:
	if player_state == PlayerState.AIR:
		pass
		
	if player_state == PlayerState.CROUCHING or player_state == PlayerState.IDLE_CROUCH:
		head.position.y = lerp(head.position.y, 1.8 + CROUCHING_DEPTH, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*0.95, delta * lerp_speed)
	elif player_state == PlayerState.IDLE_STAND:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta * lerp_speed)
	elif player_state == PlayerState.WALKING:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta * lerp_speed)
	elif player_state == PlayerState.SPRINTING:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*1.05, delta * lerp_speed)
