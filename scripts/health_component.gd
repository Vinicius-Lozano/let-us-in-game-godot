extends Node
class_name HealthComponent

# ==========================================
# SINAIS (Padrão Observer)
# ==========================================
signal health_changed(current_health: int, max_health: int)
signal took_damage(amount: int)
signal healed(amount: int)
signal died()

signal stun_started()
signal stun_ended()

# ==========================================
# VARIÁVEIS EXPORTADAS
# ==========================================
@export var max_health: int = 3
@export var default_stun_duration: float = 2.0 # Tempo base do stun exportado

# ==========================================
# ESTADO INTERNO
# ==========================================
var current_health: int
var is_stunned: bool = false
var stun_timer: Timer

func _ready() -> void:
	# Inicializa a vida com o valor máximo definido no Inspector
	current_health = max_health
	_setup_stun_timer()

func _setup_stun_timer() -> void:
	# Criamos o timer dinamicamente para não precisarmos adicionar
	# o nó Timer manualmente toda vez que usarmos esse componente.
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	stun_timer.timeout.connect(_on_stun_timeout)
	add_child(stun_timer)

# ==========================================
# LÓGICA DE DANO E CURA
# ==========================================
func take_damage(amount: int) -> void:
	if current_health <= 0:
		return # Evita processar dano em algo que já está morto
		
	current_health -= amount
	
	# max() garante que a vida nunca fique negativa. Custo matemático: O(1)
	current_health = max(0, current_health) 
	
	took_damage.emit(amount)
	health_changed.emit(current_health, max_health)
	
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return 
		
	current_health += amount
	
	# min() garante que a vida não ultrapasse o limite. Custo matemático: O(1)
	current_health = min(current_health, max_health) 
	
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

# ==========================================
# LÓGICA DE STUN (ATORDOAMENTO)
# ==========================================
func apply_stun(custom_duration: float = -1.0) -> void:
	if current_health <= 0:
		return
		
	is_stunned = true
	stun_started.emit()
	
	# Se passarmos um valor no parâmetro, ele usa o valor.
	# Se não passarmos nada, ele usa o default_stun_duration do Inspector.
	var duration = default_stun_duration if custom_duration < 0.0 else custom_duration
	stun_timer.start(duration)

func _on_stun_timeout() -> void:
	is_stunned = false
	stun_ended.emit()
