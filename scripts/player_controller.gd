extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera_3d: Camera3D = $Head/Eyes/Camera3D
@onready var standing: CollisionShape3D = $Standing
@onready var crouching: CollisionShape3D = $Crouching
@onready var standup_check: RayCast3D = $StandupCheck
@onready var interaction_controller: Node = %InteractionController
@onready var footstep_audio: AudioStreamPlayer3D = $FootstepAudio

@export var health_component: HealthComponent
# --- NOVO: Cena de transição pós-morte (Padrão Fallback) ---
@export var game_over_scene: PackedScene 

var can_play_step: bool = true
const WALKING_SPEED: float = 3.0
const SPRINTING_SPEED: float = 5.0
const CROUCHING_SPEED: float = 1.0
const CROUCHING_DEPTH: float = -0.9
const JUMP_VELOCITY: float = 4.0
const HEAD_BOBBING_SPRINTING_SPEED: float = 22.0
const HEAD_BOBBING_WALKING_SPEED: float = 14.0
const HEAD_BOBBING_CROUCHING_SPEED: float = 10.0
const HEAD_BOBBING_SPRINTING_INTENSITY: float = 0.2
const HEAD_BOBBING_WALKING_INTENSITY: float = 0.1
const HEAD_BOBBING_CROUCHING_INTENSITY: float = 0.05

var current_speed: float = 0.0
var moving: bool = false
var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO
var lerp_speed: float = 10.0
var head_bobbing_current_intensity: float = 0.0
var head_bobbing_vector: Vector2 = Vector2.ZERO
var head_bobbing_index: float = 0.0

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
	
	if health_component:
		health_component.took_damage.connect(_on_took_damage)
		# --- NOVO: Escutando a morte do jogador ---
		health_component.died.connect(_on_player_died)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('quit'):
		get_tree().quit()
	
	if event is InputEventMouseMotion:
		if not interaction_controller.isCameraLocked():
			rotate_y(deg_to_rad(-event.relative.x) * mouse_sensitivty)
			head.rotate_x(deg_to_rad(-event.relative.y) * mouse_sensitivty)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
	updatePlayerState()
	updateCamera(delta)
	
	if not is_on_floor():
		if velocity.y >= 0:
			velocity += get_gravity() * delta
		else:
			velocity += get_gravity() * delta * 2.0
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	
	input_dir = Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * 10.0)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
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
	if player_state == PlayerState.CROUCHING or player_state == PlayerState.IDLE_CROUCH:
		head.position.y = lerp(head.position.y, 1.8 + CROUCHING_DEPTH, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*0.95, delta * lerp_speed)
		head_bobbing_current_intensity = HEAD_BOBBING_CROUCHING_INTENSITY
		if moving: head_bobbing_index += HEAD_BOBBING_CROUCHING_SPEED * delta
		
	elif player_state == PlayerState.WALKING:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta * lerp_speed)
		head_bobbing_current_intensity = HEAD_BOBBING_WALKING_INTENSITY
		if moving: head_bobbing_index += HEAD_BOBBING_WALKING_SPEED * delta
		
	elif player_state == PlayerState.SPRINTING:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*1.05, delta * lerp_speed)
		head_bobbing_current_intensity = HEAD_BOBBING_SPRINTING_INTENSITY
		if moving: head_bobbing_index += HEAD_BOBBING_SPRINTING_SPEED * delta
	
	elif player_state == PlayerState.IDLE_STAND:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta * lerp_speed)

	head_bobbing_vector.y = sin(head_bobbing_index)
	head_bobbing_vector.x = (sin(head_bobbing_index/2.0)+0.5)
	
	if moving and is_on_floor():
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity/2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * (head_bobbing_current_intensity), delta * lerp_speed)
		
		if head_bobbing_vector.y < -0.9:
			if can_play_step:
				footstep_audio.pitch_scale = randf_range(0.85, 1.15)
				footstep_audio.volume_db = randf_range(-2.0, 0.0)
				footstep_audio.play()
				can_play_step = false
		
		if head_bobbing_vector.y > 0.0:
			can_play_step = true
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
		can_play_step = true 

func _on_took_damage(_amount: int) -> void:
	var tween = create_tween()
	var tilt_direction = 1 if randf() > 0.5 else -1
	var tilt_angle = deg_to_rad(5.0 * tilt_direction)
	
	tween.tween_property(camera_3d, "rotation:z", tilt_angle, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_3d, "rotation:z", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ==========================================
# LÓGICA DE MORTE E GAME OVER
# ==========================================
func _on_player_died() -> void:
	print("[PLAYER] Vida zerada! Iniciando sequência de Game Over...")
	
	# 1. Impede o jogador de andar, pular e mexer a câmera
	set_physics_process(false)
	set_process_input(false)
	
	# Remove a colisão de "pé" para o jogador cair e soltar o item que estiver segurando
	standing.disabled = true
	crouching.disabled = false
	interaction_controller.drop_item() 
	
	# 2. Feedback visual dramático (A câmera tomba para o chão)
	var tween = create_tween()
	# A câmera rola 90 graus para a direita
	tween.tween_property(camera_3d, "rotation:z", deg_to_rad(-85.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# E a cabeça desce ao nível do chão
	tween.parallel().tween_property(head, "position:y", 0.2, 0.6)
	
	# 3. Pausa dramática para o jogador perceber que morreu
	await get_tree().create_timer(2.5).timeout
	
	# 4. Solta o mouse para caso o jogador vá para o Menu Principal
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 5. O Padrão Fallback
	if game_over_scene != null:
		# Se você arrastou o Menu Principal no Inspector
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		# Se o campo está vazio, apenas reseta a fase atual
		get_tree().reload_current_scene()
