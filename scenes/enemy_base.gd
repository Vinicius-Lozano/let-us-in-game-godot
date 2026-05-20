@tool # --- NOVO: Avisa a engine que este script roda no Editor ---
extends CharacterBody3D
class_name EnemyBase

@export_category("Configuração Visual")
## Arraste aqui a cena (.tscn) contendo a malha e as animações do seu monstro
@export var model_prefab: PackedScene:
	# --- NOVO: Setter. Roda sempre que você muda a variável no Inspector ---
	set(value):
		model_prefab = value
		# Atualiza a malha instantaneamente no editor se os nós já estiverem carregados
		if Engine.is_editor_hint() and is_node_ready():
			_instantiate_model()

@export_category("Mecânicas")
@export var respawn_delay: float = 3.0
@export var safe_respawn_markers: Array[Node3D]

@export_category("Dependências Internas")
@export var health_component: HealthComponent
@export var ai_component: AIComponent
@export var visuals_container: Node3D

var initial_position: Vector3
var is_dead: bool = false
var current_model_instance: Node3D

func _ready() -> void:
	# 1. Instancia o modelo visual (Roda tanto no Jogo quanto no Editor)
	_instantiate_model()
	
	# --- NOVO: Trava de Segurança do Editor ---
	# Se estivermos rodando dentro do editor do Godot, paramos a função aqui!
	if Engine.is_editor_hint():
		return
		
	# ==========================================
	# CÓDIGO EXCLUSIVO DE JOGO (Runtime)
	# ==========================================
	# Memoriza onde nasceu para o Respawn
	initial_position = global_position
	
	# Conecta os sinais de Vida
	if health_component:
		health_component.died.connect(_on_death)
		
	# Configura o Cérebro
	if ai_component:
		ai_component.setup(self)

func _physics_process(delta: float) -> void:
	# --- NOVO: Proteção. Impede o inimigo de andar ou cair na tela de edição! ---
	if Engine.is_editor_hint():
		return
		
	if is_dead:
		return
		
	# Delega a responsabilidade de movimento para o Componente de IA
	if ai_component:
		ai_component.process_movement(delta)
		
	move_and_slide()

func _instantiate_model() -> void:
	if model_prefab == null or visuals_container == null:
		return # Falha silenciosa é aceitável no editor para não poluir o console
		
	# Limpa modelos velhos
	for child in visuals_container.get_children():
		child.queue_free()
		
	# Cria a malha da nova cena e anexa ao contêiner
	current_model_instance = model_prefab.instantiate()
	visuals_container.add_child(current_model_instance)

# ==========================================
# LÓGICA DE INTEGRAÇÃO (MORTE E RESPAWN)
# (Inalterada, pois o 'Engine.is_editor_hint()' no _ready já a protege)
# ==========================================
func _on_death() -> void:
	is_dead = true
	
	if ai_component:
		ai_component.on_death()
		
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	
	print("[ENEMY FRAMEWORK] Inimigo morreu. Aguardando Respawn...")
	execute_respawn_sequence()

func execute_respawn_sequence() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	
	global_position = initial_position
	velocity = Vector3.ZERO
	
	if health_component:
		health_component.heal(health_component.max_health)
		
	visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	is_dead = false
	
	if ai_component:
		ai_component.on_respawn()
		
	print("[ENEMY FRAMEWORK] Inimigo Respawnou na origem!")

func force_respawn_away() -> void:
	if safe_respawn_markers.size() > 0:
		var safe_marker = safe_respawn_markers.pick_random()
		if safe_marker:
			global_position = safe_marker.global_position
			print("[ENEMY FRAMEWORK] Inimigo forçado a respawnar em um ponto seguro!")
			if ai_component:
				ai_component.on_respawn()
			return
			
	# Fallback caso não existam markers configurados
	global_position = initial_position
	print("[ENEMY FRAMEWORK] Inimigo forçado a respawnar na origem (nenhum marker configurado)!")
	if ai_component:
		ai_component.on_respawn()
