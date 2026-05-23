extends Area3D

# Arraste o nó do som da floresta para cá no Inspector
@export var forest_audio: AudioStreamPlayer 

func _ready():
	# Conecta o sinal automaticamente via código
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Checa se quem entrou na caixa foi o jogador
	# (Verifica se o nome do nó é Player ou se ele tem o grupo "player")
	if body.name == "player" or body.is_in_group("player"):
		
		# Se o áudio da floresta estiver tocando
		if forest_audio and forest_audio.playing:
			print("Jogador entrou na caverna. Parando som da floresta...")
			
			var tween = create_tween()
			# Faz o som abaixar suavemente até o mudo (-80dB) em 2 segundos
			tween.tween_property(forest_audio, "volume_db", -80.0, 2.0)
			
			# Depois que o volume zerar, manda o som parar de verdade para economizar memória
			tween.tween_callback(forest_audio.stop)
			
		# Desliga essa caixa de colisão para que o efeito não rode duas vezes 
		# se o jogador der um passo pra trás
		set_deferred("monitoring", false)
