extends Node
class_name AIComponent

## Referência ao corpo que esta IA vai controlar
var body: CharacterBody3D

func setup(controlled_body: CharacterBody3D) -> void:
	body = controlled_body

# Função virtual: CADA inimigo vai reescrever essa função do seu jeito.
func process_movement(_delta: float) -> void:
	push_warning("Aviso: Esta IA base não faz nada. Crie um script que estenda AIComponent!")

# Função chamada quando o inimigo morre (para parar de processar a IA)
func on_death() -> void:
	pass

# Função chamada quando o inimigo renasce
func on_respawn() -> void:
	pass
