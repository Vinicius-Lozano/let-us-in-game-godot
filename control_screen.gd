extends Control

var can_skip: bool = false

func _ready() -> void:
	# Esconde o mouse (já que o jogo vai começar logo em seguida)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Colocamos um pequeno atraso de 0.5s antes de liberar o botão.
	# Isso evita que o jogador pule essa tela sem querer caso ele 
	# tenha dado um "duplo clique" rápido no botão Play do Menu!
	await get_tree().create_timer(0.5).timeout
	can_skip = true

func _input(event: InputEvent) -> void:
	# Só avança se o tempo de segurança passou
	if can_skip:
		# Checa se o jogador apertou qualquer tecla do teclado ou botão do mouse
		if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
			start_game()

func start_game():
	# MUDE ESTE CAMINHO PARA O NOME EXATO DO SEU MAPA PRINCIPAL!
	get_tree().change_scene_to_file("res://scenes/main_map.tscn")
