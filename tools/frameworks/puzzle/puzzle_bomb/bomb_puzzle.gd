extends Node
class_name PuzzleBomb

@export_category("Configurações do Puzzle")
@export var drop_zone: DropZone
@export var explosion_delay: float = 15.0
@export var obstacles_to_destroy: Array[Node3D]

@export_category("Efeitos (VFX e Áudio)")
@export var fuse_audio: AudioStreamPlayer3D
@export var explosion_audio: AudioStreamPlayer3D
# --- NOVO: Referência para a cena do seu shader de explosão ---
@export var explosion_vfx: PackedScene

func _ready() -> void:
	if drop_zone == null:
		push_error("[PUZZLE BOMB] A DropZone não foi plugada no Inspector!")
		return
		
	drop_zone.item_assembled.connect(_on_bomb_planted)

func _on_bomb_planted() -> void:
	print("[PUZZLE BOMB] Dinamite plantada! Corra, detonação em ", explosion_delay, " segundos.")
	
	# Toca o som do pavio queimando assim que a bomba é plantada
	if fuse_audio:
		fuse_audio.play()
	
	await get_tree().create_timer(explosion_delay).timeout
	
	execute_explosion()

func execute_explosion() -> void:
	print("[PUZZLE BOMB] KABOOM!")
	
	# Para o som do pavio (pois a bomba já explodiu)
	if fuse_audio:
		fuse_audio.stop()
		
	# Toca o estrondo da explosão
	if explosion_audio:
		explosion_audio.play()
		
	# --- NOVO: Lógica de Instanciar o Visual da Explosão ---
	if explosion_vfx and drop_zone:
		var vfx_instance = explosion_vfx.instantiate()
		# Adiciona o efeito direto na cena do mapa para ele rodar de forma independente
		get_tree().current_scene.add_child(vfx_instance)
		# Posiciona o fogo e a fumaça exatamente em cima da drop zone da dinamite
		vfx_instance.global_position = drop_zone.global_position
	
	# Destrói os obstáculos (pedras)
	for obstacle in obstacles_to_destroy:
		if obstacle != null:
			obstacle.queue_free()
			
	# Remove o modelo falso da dinamite que estava no chão
	if drop_zone and drop_zone.scenario_object:
		drop_zone.scenario_object.queue_free()
