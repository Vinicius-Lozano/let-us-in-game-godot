extends Control

@onready var logo: TextureRect = $Logo
@onready var text: Label = $Text
@onready var music: AudioStreamPlayer = $Music

var can_skip: bool = false # Impede de pular os créditos sem querer logo de cara

func _ready() -> void:
	# 1. Libera o mouse do jogador (já que o jogo acabou)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 2. Deixa a logo e o texto invisíveis
	logo.modulate.a = 0.0
	text.modulate.a = 0.0
	
	# 3. Inicia a sequência cinematográfica!
	start_credits_sequence()

func start_credits_sequence():
	# Inicia a música final
	music.play()
	
	var tween = create_tween()
	
	# Espera 2 segundos de pura tela preta e música tocando
	tween.tween_interval(2.0)
	
	# Fade In da Logo (dura 3 segundos)
	tween.tween_property(logo, "modulate:a", 1.0, 3.0)
	
	# Espera 1.5 segundos com a logo na tela
	tween.tween_interval(1.5)
	
	# Fade In do Texto dos Créditos (dura 2.5 segundos)
	tween.tween_property(text, "modulate:a", 1.0, 2.5)
	
	# Espera os créditos aparecerem totalmente e libera o pulo
	await tween.finished
	can_skip = true
	
	# Opcional: Adiciona um aviso sutil para voltar ao menu
	# text.text += "\n\n[ Pressione qualquer botão para sair ]"

# Permite voltar para o Menu Principal clicando em qualquer lugar
func _input(event: InputEvent) -> void:
	if can_skip:
		if event is InputEventMouseButton or event.is_action_pressed("ui_accept"):
			# VOLTA PARA O MENU (Atualize o caminho para a sua cena de Menu)
			get_tree().change_scene_to_file("res://tools/inventory_scripts/main_menu.tscn")
