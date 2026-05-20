@tool
extends EnemyBase
class_name MatriarcaEnemyy

@export_category("Configurações da Matriarca")
## Arraste a cena do seu Main Menu para cá no Inspector
@export var victory_scene: PackedScene 

# ==========================================
# POLIMORFISMO: Reescrevendo a morte
# ==========================================
# Quando o HealthComponent avisar que a vida zerou, o Godot chamará 
# ESTA função ao invés da função do EnemyBase original.
func _on_death() -> void:
	is_dead = true
	
	if ai_component:
		ai_component.on_death()
		
	print("[MATRIARCA] O Chefe Final foi derrotado! Iniciando sequência de vitória...")
	
	# Esconde a malha e desliga a colisão física
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	
	# Chama a lógica exclusiva de finalização do jogo
	_execute_victory_sequence()

# Função Assíncrona para não travar a thread principal do jogo
func _execute_victory_sequence() -> void:
	# Pausa dramática de 3 segundos para o jogador absorver a vitória
	await get_tree().create_timer(1.0).timeout
	
	# Destrava o mouse para o jogador poder clicar no menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Validação segura (Prevenção contra Null Pointer Exception)
	if victory_scene != null:
		get_tree().change_scene_to_packed(victory_scene)
	else:
		push_error("[MATRIARCA] Falha Crítica: Cena de Vitória não configurada no Inspector!")
