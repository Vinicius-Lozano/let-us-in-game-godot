extends CharacterBody3D

@export var speed: float = 3.0
@export var player: Node3D # Lembre-se de linkar o Player no Inspector

func _physics_process(_delta: float) -> void:
	# Safety check: Garante que o jogo não quebre se o player for destruído ou não linkado
	if player == null:
		return
		
	# ==========================================
	# 1. LÓGICA DE ROTAÇÃO (ROTATION / YAW)
	# ==========================================
	
	# Captura a posição global do alvo (Target Position)
	var target_position: Vector3 = player.global_position
	
	# Lock no eixo Y: Força o alvo virtual a ter a mesma altura do inimigo.
	# Isso impede que o modelo incline (Pitch) se o jogador pular ou agachar.
	target_position.y = global_position.y
	
	# Checagem matemática: Evita o erro de tentar olhar para o exato ponto onde já estamos
	if not global_position.is_equal_approx(target_position):
		# look_at aponta o eixo -Z do inimigo para o target_position. Vector3.UP é o topo do mundo.
		look_at(target_position, Vector3.UP)


	# ==========================================
	# 2. LÓGICA DE MOVIMENTAÇÃO (MOVEMENT)
	# ==========================================
	
	# Calcula o vetor de direção
	var direction: Vector3 = player.global_position - global_position
	
	# Zera o Y do vetor de direção para o inimigo não tentar voar/afundar
	direction.y = 0
	
	# Normaliza para manter a velocidade constante (magnitude = 1)
	direction = direction.normalized()
	
	# Aplica a direção e a velocidade ao Vector3 nativo 'velocity'
	velocity = direction * speed
	
	# Resolve a física e as colisões no ambiente 3D
	move_and_slide()
