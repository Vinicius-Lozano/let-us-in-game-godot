extends ActionData
class_name FlashlightAction

@export var time_to_respawn: float = 6.0

var spotlight: SpotLight3D
var raycast: RayCast3D
var is_on: bool = true
var time_on_target: float = 0.0
var current_target: Node3D = null

func _init() -> void:
	action_type = ActionType.FLASHLIGHT

func equip_flashlight(parent: Node3D) -> void:
	if spotlight != null:
		unequip_flashlight()
		
	# Adiciona o Spotlight
	spotlight = SpotLight3D.new()
	spotlight.light_color = Color(1.0, 0.95, 0.8)
	spotlight.light_energy = 2.0
	spotlight.spot_range = 15.0
	spotlight.spot_angle = 35.0
	spotlight.shadow_enabled = true
	# No Godot, para olhar para frente (assumindo que o parent orienta Z negativo como frente)
	spotlight.position = Vector3.ZERO
	parent.add_child(spotlight)
	
	# Adiciona o Raycast para detectar inimigos
	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0, 0, -15.0)
	raycast.collision_mask = 1 # IMPORTANTE: Ajuste isso se seus inimigos estiverem em outra mask!
	parent.add_child(raycast)
	
	is_on = true
	spotlight.visible = is_on
	print("[FLASHLIGHT] Equipada e ativada.")

func unequip_flashlight() -> void:
	if spotlight:
		spotlight.queue_free()
		spotlight = null
	if raycast:
		raycast.queue_free()
		raycast = null
	current_target = null
	time_on_target = 0.0
	print("[FLASHLIGHT] Desequipada.")

func toggle() -> void:
	is_on = !is_on
	if spotlight:
		spotlight.visible = is_on
	if not is_on:
		current_target = null
		time_on_target = 0.0
		print("[FLASHLIGHT] Desligada.")
	else:
		print("[FLASHLIGHT] Ligada.")

func process_flashlight(delta: float) -> void:
	if not is_on or raycast == null:
		return
		
	var collider = raycast.get_collider()
	if collider and collider.is_in_group("enemy"):
		if collider == current_target:
			time_on_target += delta
			if time_on_target >= time_to_respawn:
				print("[FLASHLIGHT] Inimigo cegado! Forçando respawn.")
				if collider.has_method("force_respawn_away"):
					collider.force_respawn_away()
				elif collider.has_method("execute_respawn_sequence"):
					collider.execute_respawn_sequence()
				current_target = null
				time_on_target = 0.0
		else:
			current_target = collider
			time_on_target = delta
	else:
		current_target = null
		time_on_target = 0.0
