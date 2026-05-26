extends AudioStreamPlayer # Mude para AudioStreamPlayer3D se tiver escolhido o nó 3D

@export_category("Configuração de Ambiente")
@export var sounds: Array[AudioStream]
@export var min_wait_time: float = 15.0 # Tempo mínimo para tocar um som
@export var max_wait_time: float = 40.0 # Tempo máximo de silêncio

func _ready() -> void:
	if sounds.is_empty():
		push_error("[AMBIENTE] Você não colocou nenhum som na lista do Inspector!")
		return
		
	# Inicia o ciclo infinito de áudios assim que o jogo começa
	_start_random_timer()

func _start_random_timer() -> void:
	# 1. Escolhe um tempo aleatório de silêncio
	var wait_time = randf_range(min_wait_time, max_wait_time)
	# print("[AMBIENTE] Próximo som assustador em ", wait_time, " segundos.")
	
	# 2. Espera esse tempo passar
	await get_tree().create_timer(wait_time).timeout
	
	# 3. Pega um som aleatório da sua gaveta (Array)
	stream = sounds.pick_random()
	
	# DICA SÊNIOR: Altera levemente o tom (pitch) para o mesmo som parecer diferente toda vez
	pitch_scale = randf_range(0.85, 1.15)
	
	# 4. Toca o som!
	play()
	
	# 5. Espera o som terminar de tocar antes de iniciar a contagem para o próximo
	await finished
	_start_random_timer()
