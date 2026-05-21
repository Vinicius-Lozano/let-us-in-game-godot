extends Control

@onready var art: TextureRect = $Art
@onready var text: Label = $Text
@onready var retry_button: Button = $RetryButton

# Exemplo de como carregar as duas imagens diferentes que você vai usar
# (Você pode arrastar as imagens direto pras variáveis no Inspector depois se preferir)
var rastejador_img = preload("res://gfx/UI/arte_rastejador.png")
var andarilho_img = preload("res://gfx/UI/arte_andarilho.png")

func _ready() -> void:
	# 1. Libera o mouse para o jogador poder clicar no botão
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 2. Deixa tudo invisível no começo (apenas o fundo preto aparece)
	art.modulate.a = 0.0
	text.modulate.a = 0.0
	retry_button.modulate.a = 0.0
	
	# 3. Escolhe a arte e o texto baseado em quem matou
	if Global.killer_name == "Rastejador":
		text.text = "Voce nao olhou para tras..."
		art.texture = rastejador_img
	elif Global.killer_name == "Andarilho":
		text.text = "O Gigante te pegou..."
		art.texture = andarilho_img
	else:
		text.text = "Sua mente sucumbiu..." # Caso morra pra sanidade/pílula
	
	# 4. Inicia o Fade In
	start_fade_in()

func start_fade_in():
	# Criamos a sequência de fade in (um depois do outro)
	var tween = create_tween()
	
	# Arte aparece em 2 segundos
	tween.tween_property(art, "modulate:a", 1.0, 2.0)
	# Texto aparece em 1.5 segundos (espera a arte aparecer primeiro)
	tween.tween_property(text, "modulate:a", 1.0, 1.5).set_delay(1.0)
	# Botão aparece em 1 segundo
	tween.tween_property(retry_button, "modulate:a", 1.0, 1.0).set_delay(0.5)

# Acontece quando o jogador clica no botão "Tentar Novamente"
func _on_retry_button_pressed() -> void:
	retry_button.disabled = true # Impede de clicar duas vezes
	
	var tween = create_tween()
	# Faz a tela inteira (self) sumir pro preto
	tween.tween_property(art, "modulate:a", 0.0, 1.5)
	tween.tween_property(text, "modulate:a", 0.0, 1.5)
	tween.tween_property(retry_button, "modulate:a", 0.0, 1.5)
	
	# Espera o fade out acabar
	await tween.finished
	
	# Oculta o mouse de novo e reca"res://scenes/main_map.tscn"go
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://scenes/main_map.tscn") # MUDE O CAMINHO AQUI!


func _on_retry_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(retry_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_retry_button_mouse_exited() -> void:
	var tween = create_tween()
	# Volta ao tamanho original (1.0) 
	tween.tween_property(retry_button, "scale", Vector2(1.0, 1.0), 0.1)
