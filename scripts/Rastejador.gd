extends CharacterBody3D

enum State { SEARCHING, HUNTING }
var current_state: State = State.SEARCHING

@export_group("Configurações do Rastejador")
@export var speed: float = 6.0
@export var hunt_radius: float = 35.0 # Maior que a visão do andarilho
@export var player: Node3D
@export var safe_zone: Area3D
@export var teleport_points: Array[Node3D]

# Nós Internos
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var spotted_audio: AudioStreamPlayer3D = $SpottedAudio

var player_camera: Camera3D 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var stun_timer: float = 0.0

# Variáveis do Novo Sistema de Busca
var search_dir_timer: float = 0.0
var search_teleport_timer: float = 15.0 # Tempo até teleportar se não achar o jogador
var current_search_dir: Vector3 = Vector3.ZERO
var pose_timer: float = 0.0
var ja_viu_jogador: bool = false

func _ready():
	player_camera = get_viewport().get_camera_3d()
	call_deferred("teleport_to_random_point")
	pick_random_direction()

func _physics_process(delta: float) -> void:
	# 1. GRAVIDADE
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if player == null or player_camera == null: 
		move_and_slide()
		return
		
	# 2. ATORDOAMENTO (HIT)
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = 0
		velocity.z = 0
		handle_animation(delta)
		handle_audio()
		move_and_slide()
		return

	# 3. LÓGICA DA CABANA (SAFE ZONE)
	if is_player_in_safe_zone():
		current_state = State.SEARCHING # Desiste de caçar
		if not is_being_looked_at():
			teleport_to_random_point() # Some se você virar as costas
		else:
			velocity.x = 0
			velocity.z = 0
		handle_animation(delta)
		handle_audio()
		move_and_slide()
		return

	# 4. MECÂNICA DE ESTÁTUA (Prioridade máxima)
	if is_being_looked_at():
		velocity.x = 0
		velocity.z = 0
		handle_animation(delta)
		handle_audio()
		move_and_slide()
		return

	# 5. MÁQUINA DE ESTADOS (O que ele faz quando não está sendo olhado)
	match current_state:
		State.SEARCHING:
			process_searching(delta)
		State.HUNTING:
			process_hunting(delta)

	handle_animation(delta)
	handle_audio()
	move_and_slide()

# ==========================================
# NOVOS ESTADOS DA IA
# ==========================================
func process_searching(delta: float) -> void:
	# Checa se o jogador entrou na área de caça
	if can_see_player(hunt_radius):
		current_state = State.HUNTING
		search_teleport_timer = 15.0 # Reseta o timer de teleporte
		if spotted_audio and not spotted_audio.playing:
					if not ja_viu_jogador:
						# Primeira vez: Toca do zero até o final
						print("[RASTEJADOR] Primeira vez! Tocando áudio completo.")
						spotted_audio.play(0.0)
						ja_viu_jogador = true
					else:
						# Segunda vez em diante: Toca a partir do segundo 2.0
						print("[RASTEJADOR] Já te vi antes! Tocando do seg 2 ao 7.")
						spotted_audio.play(2.0)
						# Chama a função que criamos para cortar o áudio após 5 segundos
						_stop_audio_after(7.0)
		return

	# Cronômetro para mudar de direção aleatória
	search_dir_timer -= delta
	if search_dir_timer <= 0.0:
		pick_random_direction()
		
	# Cronômetro para teleportar (se ficar muito tempo sem achar ninguém)
	search_teleport_timer -= delta
	if search_teleport_timer <= 0.0:
		teleport_to_random_point()
		search_teleport_timer = 15.0 # Reseta após teleportar
		
	# Move na direção aleatória
	look_at_target(global_position + current_search_dir)
	velocity.x = current_search_dir.x * (speed * 0.6) # Anda um pouco mais devagar ao procurar
	velocity.z = current_search_dir.z * (speed * 0.6)

func process_hunting(_delta: float) -> void:
	# Checa se o jogador fugiu pra longe
	if not can_see_player(hunt_radius * 1.2): # 1.2 dá uma "margem" pro jogador não fugir tão fácil
		current_state = State.SEARCHING
		return
		
	# Corre atrás do jogador
	look_at_target(player.global_position)
	var target_pos = player.global_position
	target_pos.y = global_position.y
	var direction = (target_pos - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

# ==========================================
# FUNÇÕES AUXILIARES
# ==========================================
func pick_random_direction():
	# Escolhe uma direção aleatória no eixo X e Z
	current_search_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	search_dir_timer = randf_range(2.0, 5.0) # Fica andando nessa direção por 2 a 5 segundos

func teleport_to_random_point() -> void:
	if teleport_points.size() > 0:
		var random_marker = teleport_points.pick_random()
		global_position = random_marker.global_position
		pick_random_direction()

func look_at_target(target: Vector3) -> void:
	target.y = global_position.y
	if not global_position.is_equal_approx(target):
		look_at(target, Vector3.UP)

func can_see_player(radius: float) -> bool:
	if global_position.distance_to(player.global_position) > radius:
		return false
		
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0,1,0), player.global_position + Vector3(0,1,0))
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	return result and result.collider == player

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

# --- GERENCIAMENTO VISUAL E SONORO ---
func handle_animation(delta: float):
	if anim_player == null: return
	# Lógica do "Stop-Motion"
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
	# Se o monstro está atordoado (levou machadada ou já acabou de bater), ele não dá dano
	if stun_timer > 0.0:
		return
		
	# Checa se em quem ele encostou tem o componente de vida do seu colega
	var health_comp = body.get_node_or_null("HealthComponent")
	
	if health_comp:
		# 1. Dá 1 de dano
		Global.killer_name = "Rastejador"
		health_comp.take_damage(1)
		
		# 2. Fica atordoado por 1.5s para o jogador não tomar hit-kill e conseguir fugir
		stun_timer = 3

# Corta o áudio após X segundos
func _stop_audio_after(duration: float) -> void:
	# O código vai "pausar" aqui por 5 segundos
	await get_tree().create_timer(duration).timeout
	
	# Trava de Segurança Sênior: Verifica se o monstro ainda existe 
	# e se o áudio ainda está tocando antes de tentar parar
	if is_instance_valid(spotted_audio) and spotted_audio.playing:
		spotted_audio.stop()
