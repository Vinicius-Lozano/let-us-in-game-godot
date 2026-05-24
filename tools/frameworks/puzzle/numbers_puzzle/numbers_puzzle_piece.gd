@tool
extends StaticBody3D
class_name NumberPuzzlePiece

@export_category("Configuração do Puzzle")

# Quando você muda esse valor no Inspector, ele atualiza a tela na hora!
@export var digit: int = 0:
	set(value):
		digit = value
		_update_visuals()

# A referência do número que está lá na parede principal
@export var wall_visual_node: Node3D

@onready var dynamic_text: Label3D = $DynamicText

func _ready() -> void:
	_update_visuals()
	
	# O código abaixo só roda DENTRO do jogo (ignora o Editor do Godot)
	if not Engine.is_editor_hint():
		if wall_visual_node:
			wall_visual_node.visible = false

# Função que altera o texto do Label3D em tempo real
func _update_visuals() -> void:
	if dynamic_text:
		dynamic_text.text = str(digit)
	elif get_node_or_null("DynamicText"):
		# Fallback de segurança para o modo @tool antes do _ready acontecer
		$DynamicText.text = str(digit)

# Função que o seu InteractionComponent deve acionar
func collect_piece() -> void:
	if wall_visual_node:
		wall_visual_node.visible = true
		
	print("[SENHA] Pedaço com o número ", digit, " foi encontrado!")
	
	# DICA: Adicione o som de folha de papel aqui, se tiver!
	
	queue_free()
