extends AIComponent
class_name StationaryAI

# Reescrevemos a função mãe, mas a deixamos vazia.
# Isso custa tempo O(1) absoluto na CPU (Nenhuma operação matemática).
func process_movement(_delta: float) -> void:
	pass
	
func on_death() -> void:
	# Se a Matriarca fizesse algum barulho de respiração, pararíamos aqui.
	pass
