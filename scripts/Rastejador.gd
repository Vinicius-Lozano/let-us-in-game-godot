extends CharacterBody3D

@export var speed: float = 6.0
@export var player: Node3D
@export var safe_zone: Area3D
@export var teleport_points: Array[Node3D] # NOVO: Arraste os Marker3D da patrulha aqui!

var player_camera: Camera3D 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var stun_timer: float = 0.0

var is_hidden_waiting: bool = false 

func _ready():
	player_camera = get_viewport().get_camera_3d()

	call_deferred("teleport_to_random_point")
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player == null or player_camera == null:
		return
	

	handle_monster_audio()


	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# 3. LÓGICA DA CABANA (SAFE ZONE)
	if is_player_in_safe_zone():
		if is_hidden_waiting:
			velocity.x = 0
			velocity.z = 0
			move_and_slide()
			return
			
		if is_being_looked_at():
			velocity.x = 0
			velocity.z = 0
			look_at_target(player.global_position)
		else:
			teleport_to_random_point()
			is_hidden_waiting = true 
			
		move_and_slide()
		return

	is_hidden_waiting = false 

	if is_being_looked_at():
		velocity.x = 0
		velocity.z = 0
	else:
		# MOVE EM DIREÇÃO AO JOGADOR
		look_at_target(player.global_position)
		var target_pos = player.global_position
		target_pos.y = global_position.y
		var direction = (target_pos - global_position).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	move_and_slide()

# --- NOVA FUNÇÃO DE ÁUDIO ROBUSTA ---
func handle_monster_audio():
	var audio_node = $AudioStreamPlayer3D

	if velocity.length() > 0.1:
		if not audio_node.playing:
			audio_node.play()
	else:
		if audio_node.playing:
			audio_node.stop()

	
	is_hidden_waiting = false 

	if is_being_looked_at():
		velocity.x = 0
		velocity.z = 0
	else:
		look_at_target(player.global_position)
		
		var target_pos = player.global_position
		target_pos.y = global_position.y
		var direction = (target_pos - global_position).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	move_and_slide()

# --- NOVA FUNÇÃO DE TELEPORTE ---
func teleport_to_random_point() -> void:
	if teleport_points.size() > 0:
		# Sorteia um dos marcadores da lista
		var random_marker = teleport_points.pick_random()
		# Move o monstro instantaneamente para a posição do marcador
		global_position = random_marker.global_position

# --- FUNÇÕES DE AJUDA ---

func look_at_target(target: Vector3) -> void:
	target.y = global_position.y
	if not global_position.is_equal_approx(target):
		look_at(target, Vector3.UP)
		# rotate_y(deg_to_rad(180)) # Descomente se o modelo ficar de costas

func is_player_in_safe_zone() -> bool:
	if safe_zone == null:
		return false 
	return safe_zone.overlaps_body(player)

func is_being_looked_at() -> bool:
	var to_enemy = (global_position - player_camera.global_transform.origin).normalized()
	var forward = -player_camera.global_basis.z
	var dot_product = forward.dot(to_enemy)
	
	if dot_product > 0.5:
		var space_state = get_world_3d().direct_space_state
		var origin = player_camera.global_transform.origin
		var target = global_position + Vector3(0, 1.0, 0)
		var query = PhysicsRayQueryParameters3D.create(origin, target)
		query.exclude = [self.get_rid()]
		
		var result = space_state.intersect_ray(query)
		if not result or result.collider.is_in_group("player"): 
			return true
			
	return false

func take_hit() -> void:
	stun_timer = 4.0
