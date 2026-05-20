extends Node3D

@export var max_distance: float = 15.0
@export var time_to_respawn: float = 6.0

var is_on: bool = true
var time_on_target: float = 0.0
var current_target: Node3D = null

var spotlight: SpotLight3D
var raycast: RayCast3D

func _ready() -> void:
	# Procura por um SpotLight3D filho
	for child in get_children():
		if child is SpotLight3D:
			spotlight = child
			break
			
	# Cria o RayCast3D dinamicamente para facilitar o setup
	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0, 0, -max_distance)
	raycast.collision_mask = 1 # Ajuste conforme a collision_mask dos inimigos!
	add_child(raycast)
	
	if spotlight:
		spotlight.visible = is_on

func toggle() -> void:
	is_on = !is_on
	if spotlight:
		spotlight.visible = is_on
		
	if not is_on:
		reset_target()
		print("[FLASHLIGHT] Desligada.")
	else:
		print("[FLASHLIGHT] Ligada.")

func _process(delta: float) -> void:
	if not is_on:
		return
		
	var collider = raycast.get_collider()
	
	if collider and collider.is_in_group("enemy"):
		if collider == current_target:
			time_on_target += delta
			if time_on_target >= time_to_respawn:
				# Atingiu os 6 segundos
				print("[FLASHLIGHT] Inimigo cegado! Forçando respawn.")
				if collider.has_method("force_respawn_away"):
					collider.force_respawn_away()
				elif collider.has_method("execute_respawn_sequence"):
					# Fallback se a versão base for usada
					collider.execute_respawn_sequence()
					
				reset_target()
		else:
			# Novo alvo ou primeiro alvo
			current_target = collider
			time_on_target = delta
	else:
		# Não está olhando para nenhum inimigo
		if current_target != null:
			reset_target()

func reset_target() -> void:
	current_target = null
	time_on_target = 0.0
