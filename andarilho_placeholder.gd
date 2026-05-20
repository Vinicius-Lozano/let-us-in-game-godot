extends CharacterBody3D

enum State { WANDER, CHASE }
var current_state: State = State.WANDER

@export_group("Configurações do Andarilho")
@export var walk_speed: float = 2.0
@export var chase_speed: float = 4.5
@export var sight_range: float = 20.0

@export_group("Referências")
@export var player: Node3D
@export var safe_zone: Area3D
@export var patrol_points: Array[Node3D]

# Nós Internos
@onready var anim_player: AnimationPlayer = %AnimationPlayer 
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_patrol_index: int = 0
var stun_timer: float = 0.0

func _physics_process(delta: float) -> void:
	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if player == null: return

	# 2. Atordoamento (Stun do Machado)
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = 0
		velocity.z = 0
		handle_animation()
		handle_audio()
		move_and_slide()
		return 

	# 3. Máquina de Estados da IA
	match current_state:
		State.WANDER:
			process_wander(delta)
		State.CHASE:
			process_chase(delta)

	# 4. Atualiza Visuais e Som
	handle_animation()
	handle_audio()
	move_and_slide()

# --- ESTADOS DA IA ---
func process_wander(_delta: float) -> void:
	if can_see_player() and not is_player_in_safe_zone():
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

func process_chase(_delta: float) -> void:
	if is_player_in_safe_zone() or not can_see_player():
		current_state = State.WANDER
		return
		
	move_towards(player.global_position, chase_speed)

func move_towards(target_pos: Vector3, speed: float) -> void:
	var target = target_pos
	target.y = global_position.y
	
	if not global_position.is_equal_approx(target):
		look_at(target, Vector3.UP)
		
	var direction = (target - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

# --- GERENCIAMENTO VISUAL E SONORO ---
func handle_animation():
	# 1. Se ele ainda está atordoado, deixa a animação de hit rodar e ignora o resto
	if stun_timer > 0.0:
		return
		
	# 2. Se o atordoamento já acabou, mas o Godot ainda tá tocando o hit, interrompe na marra!
	if anim_player and anim_player.current_animation == "hit":
		anim_player.stop()

	# 3. Lógica normal (Andar ou Parado)
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

# --- FUNÇÕES DE DETECÇÃO E DANO ---
func take_hit() -> void:
	stun_timer = 4.0
	play_animation("hit")

func can_see_player() -> bool:
	var dist = global_position.distance_to(player.global_position)
	if dist > sight_range: return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0,1.0,0), player.global_position + Vector3(0,1.0,0))
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	return result and result.collider == player

func is_player_in_safe_zone() -> bool:
	return safe_zone.overlaps_body(player) if safe_zone else false
	
func _on_damage_area_body_entered(body: Node3D) -> void:
	# Se o monstro já está atordoado, ele não consegue bater
	if stun_timer > 0.0:
		return
		
	# Checa se em quem ele bateu tem o componente de vida do seu amigo
	var health_comp = body.get_node_or_null("HealthComponent")
	
	if health_comp:
		# 1. Dá 1 de dano no jogador
		health_comp.take_damage(1)
		
		# 2. O monstro fica atordoado por 1.5 segundos para o jogador poder fugir
		stun_timer = 1.5
		
		# 3. (Opcional) Toca a animação de Idle para ele "parar" enquanto o jogador foge
		play_animation("hit")
