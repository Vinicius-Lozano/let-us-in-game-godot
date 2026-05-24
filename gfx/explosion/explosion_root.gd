extends Node3D

func _ready() -> void:
	var max_lifetime: float = 0.0
	
	# 1. Procura todas as partículas dentro deste Node3D e manda explodir
	for child in get_children():
		if child is GPUParticles3D:
			child.emitting = true
			child.restart() # Garante que a animação comece do zero
			
			# Descobre qual partícula demora mais para sumir
			if child.lifetime > max_lifetime:
				max_lifetime = child.lifetime
				
	# 2. O Maestro espera o tempo exato da partícula mais longa terminar (+ um chorinho)
	await get_tree().create_timer(max_lifetime + 0.2).timeout
	
	# 3. Apaga o Node3D inteiro e todas as partículas filhas da memória
	queue_free()
