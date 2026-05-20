extends Node

@export_category("Componentes")
@export var health_component: HealthComponent
@export var sanity_controller: Node 

@export_category("UI")
@export var damage_overlay: TextureRect 

@export_category("Áudios")
@export var heartbeat_audio: AudioStreamPlayer
@export var hit_audio: AudioStreamPlayer
# Agora usamos uma lista/array para os 3 sussurros
@export var whispers: Array[AudioStreamPlayer2D] 

var current_hp: int = 3
var time_passed: float = 0.0
var heart_timer: float = 0.0

func _ready() -> void:
	if health_component:
		health_component.took_damage.connect(_on_took_damage)
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		current_hp = health_component.max_health
	
	if damage_overlay:
		damage_overlay.modulate.a = 0.0
		damage_overlay.visible = true

func _process(delta: float) -> void:
	time_passed += delta
	
	handle_heartbeat_logic(delta)
	handle_whisper_logic(delta) # Mudamos o nome aqui
	handle_overlay_visuals(delta)

# ==========================================
# 1. LOGICA DE SUSSURROS (SOBREPOSIÇÃO)
# ==========================================
func handle_whisper_logic(_delta: float):
	if sanity_controller == null or whispers.size() < 3:
		return

	var sanity = sanity_controller.sanity
	
	# Camada 1: Começa aos 80 de sanidade
	process_single_whisper(whispers[0], sanity, 80.0, 0.0, 1.0)
	
	# Camada 2: Entra aos 55 de sanidade (Voz mais grossa/lenta)
	process_single_whisper(whispers[1], sanity, 55.0, -5.0, 0.85)
	
	# Camada 3: Entra aos 30 de sanidade (Voz mais aguda/rápida)
	process_single_whisper(whispers[2], sanity, 30.0, -10.0, 1.15)

func process_single_whisper(audio_node: AudioStreamPlayer2D, sanity: float, threshold: float, base_db: float, pitch: float):
	if sanity < threshold:
		if not audio_node.playing:
			audio_node.play()
		
		# Calcula a intensidade baseada em quanto abaixo do limite a sanidade está
		var intensity = (threshold - sanity) / threshold
		
		# O volume vai de -40dB (quase mudo) até o volume base + um bônus de pânico
		audio_node.volume_db = lerp(-40.0, base_db + 8.0, intensity)
		audio_node.pitch_scale = pitch
	else:
		if audio_node.playing:
			audio_node.stop()

# ==========================================
# 2. RITMO DO CORAÇÃO (MANTIDO IGUAL)
# ==========================================
func handle_heartbeat_logic(delta: float):
	if heartbeat_audio == null: return
	if current_hp >= 3:
		if heartbeat_audio.playing: heartbeat_audio.stop()
		return

	heart_timer -= delta
	if heart_timer <= 0.0:
		var interval = 1.2 if current_hp == 2 else 0.6
		heart_timer = interval
		heartbeat_audio.play()
		heartbeat_audio.volume_db = 5.0 if current_hp == 2 else 15.0

# ==========================================
# 3. VISUAL DO SANGUE (MANTIDO IGUAL)
# ==========================================
func handle_overlay_visuals(delta: float):
	if not damage_overlay: return
	var target_alpha = 0.0
	var pulse_speed = 1.0
	if current_hp == 2:
		target_alpha = 0.2
		pulse_speed = 3.0
	elif current_hp <= 1:
		target_alpha = 0.5
		pulse_speed = 6.0

	if current_hp < 3:
		var pulse = (sin(time_passed * pulse_speed) * 0.1) + target_alpha
		damage_overlay.modulate.a = lerp(damage_overlay.modulate.a, pulse, delta * 2.0)
	else:
		damage_overlay.modulate.a = lerp(damage_overlay.modulate.a, 0.0, delta * 4.0)

# ==========================================
# SINAIS E SEGURANÇA
# ==========================================
func _on_took_damage(_amount: int) -> void:
	if hit_audio: hit_audio.play()
	if damage_overlay: damage_overlay.modulate.a = 1.0 

func _on_health_changed(new_hp: int, _max_hp: int) -> void:
	current_hp = new_hp

func _on_died() -> void:
	# Para todos os sussurros na morte
	for w in whispers:
		w.stop()
	if heartbeat_audio: heartbeat_audio.stop()
	get_tree().call_deferred("reload_current_scene")
