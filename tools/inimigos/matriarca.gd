@tool
extends EnemyBase
class_name MatriarcaEnemyy

@export_category("Configurações da Matriarca")
## Use o CAMINHO em string da cena de vitória (ex: "res://tools/inventory_scripts/main_menu.tscn")
## IMPORTANTE: Não use PackedScene aqui — causaria dependência circular de cenas!
@export var victory_scene_path: String = "res://tools/inventory_scripts/main_menu.tscn"

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
	# Pausa dramática para o jogador absorver a vitória
	await get_tree().create_timer(1.0).timeout

	# Destrava o mouse para o jogador poder clicar no menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Carrega a cena sob demanda (evita dependência circular de inicialização)
	if victory_scene_path != "":
		var packed = load(victory_scene_path)
		if packed:
			get_tree().change_scene_to_packed(packed)
		else:
			push_error("[MATRIARCA] Falha ao carregar cena de vitória: " + victory_scene_path)
	else:
		push_error("[MATRIARCA] Falha Crítica: 'victory_scene_path' não configurado no Inspector!")
