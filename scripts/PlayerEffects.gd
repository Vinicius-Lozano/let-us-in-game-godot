extends Node

@export_category("Componentes")
@export var health_component: HealthComponent
@export var sanity_controller: Node 

@export_category("UI")
@export var damage_overlay: TextureRect 
@export var notification_label: Label

@export_category("Áudios")
@export var heartbeat_audio: AudioStreamPlayer
@export var hit_audio: AudioStreamPlayer
# Agora usamos uma lista/array para os 3 sussurros
@export var whispers: Array[AudioStreamPlayer2D] 

@export_category("Notas")
@export var note_panel: Control
@export var note_text_label: Label

var current_hp: int = 3
var time_passed: float = 0.0
var heart_timer: float = 0.0
var can_close_note: bool = false

func _ready() -> void:
	if health_component:
		health_component.took_damage.connect(_on_took_damage)
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		current_hp = health_component.max_health
	
	if damage_overlay:
		damage_overlay.modulate.a = 0.0
		damage_overlay.visible = true
	if notification_label:
		notification_label.modulate.a = 0.0 # Começa invisível
		
	# Conecta o sinal Global à nossa nova função
	Global.show_notification.connect(_on_show_notification)
	
	Global.open_note_ui.connect(_on_open_note_ui)
	if note_panel: note_panel.visible = false
	
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
		if w != null and w.playing:
			w.stop()
			
	# Para o som do coração batendo
	if heartbeat_audio and heartbeat_audio.playing:
		heartbeat_audio.stop()
 # Arraste o label no Inspector

func show_notification(text: String):
	if notification_label == null: return
	
	notification_label.text = text
	var tween = create_tween()
	# Aparece rápido
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	# Fica na tela por 3 segundos
	tween.tween_interval(3.0)
	# Some devagar
	tween.tween_property(notification_label, "modulate:a", 0.0, 1.0)
func _on_show_notification(message: String) -> void:
	if notification_label == null: return
	
	notification_label.text = message
	
	var tween = create_tween()
	# Aparece rápido
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	# Espera 3 segundos
	tween.tween_interval(3.0)
	# Fica invisível devagar
	tween.tween_property(notification_label, "modulate:a", 0.0, 1.0)

func _on_open_note_ui(text: String) -> void:
	if note_panel == null: return
	
	note_text_label.text = text
	note_panel.visible = true
	
	# Trava o fechamento por 0.1 segundos para impedir que 
	# o clique que abriu a nota também feche ela acidentalmente!
	can_close_note = false
	await get_tree().create_timer(0.1).timeout
	can_close_note = true

func _input(event: InputEvent) -> void:
	if note_panel and note_panel.visible and can_close_note:
		# Se for um CLIQUE do mouse (qualquer botão) OU as teclas de atalho
		if (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
			note_panel.visible = false
			can_close_note = false
