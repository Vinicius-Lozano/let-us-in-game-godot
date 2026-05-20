extends Node3D
class_name MainMenu

# ==========================================
# DEPENDÊNCIAS
# ==========================================
# Caminho da cena do jogo em string para evitar dependência circular!
# (main_menu.tscn é referenciada pelo main_map.tscn, então não pode
#  referenciar o main_map.tscn de volta como PackedScene)
@export var gameplay_scene_path: String = "res://scenes/main_map.tscn"

# Referências diretas aos botões
@onready var btn_jogar: Button = $CanvasLayer/UI/VBoxContainer/BtnJogar
@onready var btn_opcoes: Button = $CanvasLayer/UI/VBoxContainer/BtnOpcoes
@onready var btn_sair: Button = $CanvasLayer/UI/VBoxContainer/BtnSair

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	btn_opcoes.pressed.connect(_on_btn_opcoes_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)
	btn_jogar.grab_focus()

# ==========================================
# MÉTODOS DE AÇÃO DOS BOTÕES
# ==========================================

func _on_btn_jogar_pressed() -> void:
	if gameplay_scene_path != "":
		print("[MENU] Iniciando o jogo...")
		var packed = load(gameplay_scene_path)
		if packed:
			get_tree().change_scene_to_packed(packed)
		else:
			push_error("[MENU] Falha ao carregar cena: " + gameplay_scene_path)
	else:
		push_error("[MENU] 'gameplay_scene_path' não configurado no Inspector!")

func _on_btn_opcoes_pressed() -> void:
	print("[MENU] Abrindo opções...")

func _on_btn_sair_pressed() -> void:
	print("[MENU] Encerrando o jogo...")
	get_tree().quit()
