extends CharacterBody3D

enum State { WANDER, CHASE }
var current_state: State = State.WANDER

@export_group("Configurações do Andarilho")
@export var walk_speed: float = 2.0
@export var chase_speed: float = 4.5
@export var sight_range: float = 20.0 
@export var fov_angle: float = 90.0   
@export var hearing_radius: float = 7.0 # Aumentei levemente para compensar a corrida

@export_group("Referências")
@export var player: Node3D
@export var safe_zone: Area3D
@export var patrol_points: Array[Node3D]

@onready var anim_player: AnimationPlayer = %AnimationPlayer 
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_patrol_index: int = 0
var stun_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		
	if player == null:
		move_and_slide()
		return

	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = 0
		velocity.z = 0
		handle_animation()
		handle_audio()
		move_and_slide()
		return 

	match current_state:
		State.WANDER:
			process_wander(delta)
		State.CHASE:
			process_chase(delta)

	handle_animation()
	handle_audio()
	move_and_slide()

# --- LÓGICA DE PATRULHA ---
func process_wander(_delta: float) -> void:
	# Tenta detectar o jogador para começar a caça
	if can_detect_player() and not is_player_in_safe_zone():
		current_state = State.CHASE
		return
		
	if patrol_points.is_empty(): 
		velocity.x = 0
		velocity.z = 0
		return 
		
	var target = patrol_points[current_patrol_index].global_position
	if global_position.distance_to(target) < 1.5:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		
	move_towards(target, walk_speed)

# --- LÓGICA DE CAÇA (CHASE) CORRIGIDA ---
func process_chase(_delta: float) -> void:
	# No Chase, ignoramos agachamento e ângulo. 
	# Ele só desiste se:
	# 1. Você entrar na Safe Zone
	# 2. Você fugir para muito longe (Sight Range * 1.5)
	# 3. Você quebrar a linha de visão (atrás de paredes)
	
	var dist = global_position.distance_to(player.global_position)
	var too_far = dist > (sight_range * 1.5)
	
	if is_player_in_safe_zone() or too_far or not has_line_of_sight():
		current_state = State.WANDER
		return
		
	move_towards(player.global_position, chase_speed)

# --- SISTEMA DE DETECÇÃO (STEALTH) ---
func can_detect_player() -> bool:
	var dist = global_position.distance_to(player.global_position)
	if dist > sight_range: return false
	if not has_line_of_sight(): return false 

	# 1. NOVA CHECAGEM DE AUDIÇÃO: Apenas se o jogador estiver CORRENDO
	if dist <= hearing_radius:
		if "player_state" in player:
			var p_state = player.get("player_state")
			# 4 é o IDLE/WALK/SPRINTING dependendo do seu Enum. 
			# Pelo seu script, SPRINTING é o estado 4.
			if p_state == 4: 
				return true # Correu perto dele? Ele te ouve e vira.

	# 2. CHECAGEM DE VISÃO (CONE FRONTAL)
	# Aqui ele te vê mesmo se você estiver agachado, se estiver na frente dele.
	var to_player = (player.global_position - global_position).normalized()
	var forward = -global_transform.basis.z 
	var angle = rad_to_deg(acos(forward.dot(to_player)))
	
	if angle <= (fov_angle / 2.0):
		return true

	return false

# Função auxiliar para o Raycast
func has_line_of_sight() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0,1.5,0), player.global_position + Vector3(0,1.5,0))
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	return result and result.collider == player

# --- FUNÇÕES RESTANTES (MOVIMENTO, ANIMAÇÃO, DANO) ---

func move_towards(target_pos: Vector3, speed: float) -> void:
	var target = target_pos
	target.y = global_position.y
	if not global_position.is_equal_approx(target):
		look_at(target, Vector3.UP)
	var direction = (target - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func handle_animation():
	if anim_player and anim_player.current_animation == "hit" and anim_player.is_playing():
		return
	if velocity.length() > 0.2:
		play_animation("WalkAnd")
	else:
		play_animation("hit")

func play_animation(anim_name: String):
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func handle_audio():
	if velocity.length() > 0.2:
		if not audio_player.playing: audio_player.play()
	else:
		audio_player.stop()

func take_hit() -> void:
	stun_timer = 4.0
	play_animation("hit")

func is_player_in_safe_zone() -> bool:
	return safe_zone.overlaps_body(player) if safe_zone else false

func _on_damage_area_body_entered(body: Node3D) -> void:
	if stun_timer > 0.0: return
	var health_comp = body.get_node_or_null("HealthComponent")
	if health_comp:
		Global.killer_name = "Andarilho"
		health_comp.take_damage(1)
		stun_timer = 1.5
		play_animation("hit")
