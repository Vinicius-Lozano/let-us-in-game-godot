extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var fade_rect: ColorRect = $ColorRect

var is_transitioning: bool = false

func _ready() -> void:
	# Oculta o mouse na intro
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Deixa a "cortina preta" transparente para o vídeo aparecer
	fade_rect.modulate.a = 0.0

# Detecta cliques ou a tecla de pular
func _input(event: InputEvent) -> void:
	if is_transitioning: return
	
	# Se clicar, apertar Espaço ou Enter, pula o vídeo
	if event is InputEventMouseButton or event.is_action_pressed("ui_accept"):
		start_transition()

# Essa função roda sozinha quando o vídeo acaba (Lembre de conectar o sinal!)
func _on_video_stream_player_finished() -> void:
	if not is_transitioning:
		start_transition()

func start_transition() -> void:
	is_transitioning = true
	
	var tween = create_tween()
	# Faz a cortina preta ficar opaca em 1 segundo (Fade Out do vídeo)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	
	# Espera a tela ficar toda preta
	await tween.finished
	
	# Carrega o Menu Principal
	get_tree().change_scene_to_file("res://tools/inventory_scripts/main_menu.tscn") # ATUALIZE O CAMINHO AQUI!
