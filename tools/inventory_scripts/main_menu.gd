extends Node3D
class_name MainMenu

# ==========================================
# DEPENDÊNCIAS (Injeção via Editor)
# ==========================================
# Expondo a variável para você arrastar a cena do jogo (main_map.tscn) no Inspector
@export var gameplay_scene: PackedScene 

# Referências diretas aos botões (Tempo de busca O(1) na memória)
@onready var btn_jogar: Button = $CanvasLayer/UI/VBoxContainer/BtnJogar
@onready var btn_opcoes: Button = $CanvasLayer/UI/VBoxContainer/BtnOpcoes
@onready var btn_sair: Button = $CanvasLayer/UI/VBoxContainer/BtnSair

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	# 1. Libera o mouse para o jogador poder clicar na UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 2. Conecta os sinais dos botões via código (Evita bugs de interface no Editor)
	# Isso garante que se você mudar o nome do nó, a conexão não quebra silenciosamente.
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	btn_opcoes.pressed.connect(_on_btn_opcoes_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)
	
	# 3. Foca no botão jogar (Útil se o jogador usar o teclado ou controle)
	btn_jogar.grab_focus()

# ==========================================
# MÉTODOS DE AÇÃO DOS BOTÕES
# ==========================================

func _on_btn_jogar_pressed() -> void:
	# Programação Defensiva: Verifica se a cena não é nula antes de tentar carregar
	if gameplay_scene != null:
		print("[MENU] Iniciando o jogo...")
		get_tree().change_scene_to_packed(gameplay_scene)
	else:
		# Fail-fast: Avisa exatamente onde está o erro
		print("[ERRO FATAL] A cena do jogo não foi definida! Arraste sua cena para 'Gameplay Scene' no Inspector do MainMenu.")

func _on_btn_opcoes_pressed() -> void:
	print("[MENU] Abrindo opções...")
	# Futuramente, você pode instanciar o menu de opções aqui ou alternar a visibilidade de outro painel.

func _on_btn_sair_pressed() -> void:
	print("[MENU] Encerrando o jogo...")
	# Comando oficial e seguro para fechar a aplicação
	get_tree().quit()
