extends CharacterBody3D

@export_group("Configurações do Rastejador")
@export var speed: float = 6.0
@export var player: Node3D
@export var safe_zone: Area3D
@export var teleport_points: Array[Node3D]

# --- NOVO: Variável de tempo exposta para o Editor ---
@export var respawn_delay: float = 3.0 # Segundos que ele fica parado após bater
# ----------------------------------------------------

# Nós Internos
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var player_camera: Camera3D 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var stun_timer: float = 0.0
var is_hidden_waiting: bool = false 
var pose_timer: float = 0.0

# --- NOVO: Variáveis de Memória e Estado ---
var initial_position: Vector3
var is_respawning: bool = false
# -------------------------------------------

func _ready():
	player_camera = get_viewport().get_camera_3d()
	
	# --- NOVO: Grava a posição exata de onde ele começou na fase ---
	initial_position = global_position
	
	call_deferred("teleport_to_random_point")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if player == null or player_camera == null:
		move_and_slide() # Aplica a queda no chão
		return
		
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = 0
		velocity.z = 0
		handle_animation(delta)
		handle_audio()
		move_and_slide()
		return

	if is_player_in_safe_zone():
		if is_hidden_waiting:
			velocity.x = 0
			velocity.z = 0
			handle_animation(delta)
			handle_audio()
			move_and_slide()
			return
			
		if is_being_looked_at():
			velocity.x = 0
			velocity.z = 0
			look_at_target(player.global_position)
		else:
			teleport_to_random_point()
			is_hidden_waiting = true 
			
		handle_animation(delta)
		handle_audio()
		move_and_slide()
		return

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

	handle_animation(delta)
	handle_audio()
	move_and_slide()

# --- FUNÇÕES ÚNICAS DO RASTEJADOR ---
func teleport_to_random_point() -> void:
	if teleport_points.size() > 0:
		var random_marker = teleport_points.pick_random()
		global_position = random_marker.global_position

func look_at_target(target: Vector3) -> void:
	target.y = global_position.y
	if not global_position.is_equal_approx(target):
		look_at(target, Vector3.UP)

func is_being_looked_at() -> bool:
	var to_enemy = (global_position - player_camera.global_transform.origin).normalized()
	var forward = -player_camera.global_basis.z
	var dot_product = forward.dot(to_enemy)
	
	if dot_product > 0.5:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(player_camera.global_transform.origin, global_position + Vector3(0, 1.0, 0))
		query.exclude = [self.get_rid()]
		var result = space_state.intersect_ray(query)
		if not result or result.collider.is_in_group("player"): 
			return true
	return false

func handle_animation(delta: float):
	if anim_player == null: return

	if velocity.length() > 0.2:
		pose_timer -= delta
		if pose_timer <= 0.0:
			pose_timer = randf_range(0.1, 0.3) 
			anim_player.play("rastejador/Rastejas")
			var length = anim_player.current_animation_length
			anim_player.seek(randf_range(0.0, length), true)
			anim_player.pause() 
	else:
		anim_player.pause()

func handle_audio():
	if velocity.length() > 0.2:
		if not audio_player.playing: audio_player.play()
	else:
		audio_player.stop()

func take_hit() -> void:
	stun_timer = 4.0
	
func is_player_in_safe_zone() -> bool:
	return safe_zone.overlaps_body(player) if safe_zone else false
	
func _on_damage_area_body_entered(body: Node3D) -> void:
	# --- NOVO: Impede danos duplos se já estiver atordoado ou respawnando ---
	if stun_timer > 0.0 or is_respawning:
		return
		
	var health_comp = body.get_node_or_null("HealthComponent")
	
	if health_comp:
		# 1. Dá 1 de dano no jogador
		health_comp.take_damage(1)
		
		# 2. Inicia a sequência assíncrona de respawn
		execute_respawn_sequence()

# --- NOVO: Lógica Assíncrona de Respawn ---
# --- NOVO: Lógica Assíncrona de Respawn com Logs e Reset Físico ---
func execute_respawn_sequence() -> void:
	# 1. LOG DE ENTRADA: Avisa que a sequência começou
	print("[RASTEJADOR] Acertei o player! Pausando IA por ", respawn_delay, " segundos.")
	
	# Trava o estado para ele não tentar andar ou dar mais dano
	is_respawning = true
	stun_timer = respawn_delay 
	
	# Pausa a execução DESTA FUNÇÃO (mas não do jogo) pelo tempo estipulado
	await get_tree().create_timer(respawn_delay).timeout
	
	# 2. LOG DE SAÍDA: Avisa para onde ele está indo
	print("[RASTEJADOR] Tempo esgotado! Teleportando de volta para XYZ: ", initial_position)
	
	# O tempo acabou! Teleporta de volta para a origem.
	global_position = initial_position
	velocity = Vector3.ZERO # Zera a física (inércia) para evitar que ele deslize após teleportar
	
	# Libera os estados para ele voltar a caçar normalmente
	is_respawning = false
	stun_timer = 0.0
	
	# Resetando a flag do esconderijo para a inteligência artificial reiniciar limpa
	is_hidden_waiting = false
