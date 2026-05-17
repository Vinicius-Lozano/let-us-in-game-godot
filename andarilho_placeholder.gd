extends CharacterBody3D

enum State { WANDER, CHASE }
var current_state: State = State.WANDER

@export_category("Configurações do Monstro")
@export var wander_speed: float = 2.0
@export var chase_speed: float = 4.5
@export var sight_range: float = 20.0 # Distância máxima que o monstro enxerga

@export_category("Referências (Arraste do Inspector)")
@export var player: Node3D
@export var safe_zone: Area3D # Arraste a Area3D da cabana pra cá
@export var patrol_points: Array[Node3D] # Adicione os Marker3D das bordas do mapa aqui

@onready var WalkS = $AudioStreamPlayer3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_patrol_index: int = 0
var stun_timer: float = 0.0 # <- Variável do atordoamento

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if player == null:
		return
		
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = 0
		velocity.z = 0
		move_and_slide() 
		return
		
	match current_state:
		State.WANDER:
			process_wander(delta)
		State.CHASE:
			process_chase(delta)
			
	move_and_slide()
	
	if velocity.length() > 0.2:
		if not WalkS.playing:
			WalkS.play()
	else:
		# Se ele parar (ou estiver atordoado), o som para
		WalkS.stop()

func process_wander(_delta: float) -> void:
	if can_see_player() and not is_player_in_safe_zone():
		current_state = State.CHASE
		return 
		
	if patrol_points.is_empty():
		return 
		
	var target_position = patrol_points[current_patrol_index].global_position
	
	if global_position.distance_to(target_position) < 1.5:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		
	move_towards_target(target_position, wander_speed)

func process_chase(_delta: float) -> void:

	if is_player_in_safe_zone() or not can_see_player():
		current_state = State.WANDER
		return # Volta pra patrulha
		
	move_towards_target(player.global_position, chase_speed)

func move_towards_target(target_pos: Vector3, speed: float) -> void:
	var target = target_pos
	target.y = global_position.y # Trava a altura para não olhar pro céu/chão
	
	if not global_position.is_equal_approx(target):
		look_at(target, Vector3.UP)
		
	var direction = (target - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func can_see_player() -> bool:
	var distance = global_position.distance_to(player.global_position)
	if distance > sight_range:
		return false # Muito longe, não vê
		
	var space_state = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 1.5, 0)
	var target = player.global_position + Vector3(0, 1.5, 0)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [self.get_rid()] # Ignora a colisão do próprio monstro
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == player:
		return true
		
	return false

func take_hit() -> void:
	stun_timer = 2.0

func is_player_in_safe_zone() -> bool:
	if safe_zone == null:
		return false # Se você não linkar a cabana, nenhum lugar é seguro!
	return safe_zone.overlaps_body(player)
