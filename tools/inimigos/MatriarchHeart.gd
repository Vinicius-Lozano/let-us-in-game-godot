extends StaticBody3D

@export_category("Referências")
@export var player: CharacterBody3D
@export var cave_entrance_marker: Marker3D # Crie um Marker3D na porta da caverna e arraste aqui

@export_category("Luzes e Animação")
@export var pulse_light: OmniLight3D
@export var heart_mesh: Node3D # A malha do coração para aumentar de tamanho
@export var heart_anim: AnimationPlayer # Animação do batimento (Idle)

@export_category("Partículas")
@export var falling_rocks: GPUParticles3D
@export var blood_phase1: GPUParticles3D
@export var blood_phase2: GPUParticles3D

@export_category("Áudios")
@export var heartbeat_audio: AudioStreamPlayer3D
@export var roar_audio: AudioStreamPlayer3D
@export var boss_music: AudioStreamPlayer

var hit_count: int = 0
var is_invulnerable: bool = false # Evita que o jogador bata duas vezes seguidas muito rápido

func _ready():
	# Começa o batimento base
	if heartbeat_audio: heartbeat_audio.play()
	if heart_anim: 
		heart_anim.play("Heartbeat")

func take_hit():
	# Se estiver invulnerável (durante o rugido), o hit não conta
	if is_invulnerable: return
	
	hit_count += 1
	is_invulnerable = true
	
	match hit_count:
		1:
			trigger_phase_1()
		2:
			trigger_phase_2()
		3:
			trigger_finale()

# ==========================================
# FASE 1 (Primeiro Golpe)
# ==========================================
func trigger_phase_1():
	print("FASE 1 INICIADA!")
	roar_audio.play()
	boss_music.play()
	falling_rocks.emitting = true
	blood_phase1.emitting = true
	
	# Acelera o coração
	heartbeat_audio.pitch_scale = 1.3
	if heart_anim: heart_anim.speed_scale = 1.3
	
	# Efeitos Cinemáticos via Tween
	var tween = create_tween()
	# Coração cresce 20%
	tween.tween_property(heart_mesh, "scale", Vector3(3, 3, 3), 0.5).set_trans(Tween.TRANS_BOUNCE)
	# Luz vermelha fica fortíssima
	tween.tween_property(pulse_light, "light_energy", 1.0, 5.0)
	
	# Empurra o jogador
	if player: 
		player.apply_knockback(global_position, 40.0)
		player.set_slow_debuff()
		player.apply_roar_shake(5.0, 2.0)
	
	# TELEPORTA OS INIMIGOS PARA A PORTA DA CAVERNA
	trap_player()
	
	# Fica invulnerável por 2 segundos enquanto a cena rola
	await get_tree().create_timer(2.0).timeout
	is_invulnerable = false

# ==========================================
# FASE 2 (Segundo Golpe)
# ==========================================
func trigger_phase_2():
	print("FASE 2 INICIADA!")
	roar_audio.play()
	blood_phase2.emitting = true
	
	# Acelera MAIS o coração
	heartbeat_audio.pitch_scale = 1.8
	if heart_anim: heart_anim.speed_scale = 1.8
	
	var tween = create_tween()
	# Cresce mais um pouco e palpita
	tween.tween_property(heart_mesh, "scale", Vector3(1.4, 1.4, 1.4), 0.2)
	tween.tween_property(pulse_light, "light_energy", 10.0, 0.2)
	
	# Empurra mais forte e deixa o jogador lento!
	if player: 
		player.apply_knockback(global_position, 40.0)
		player.set_slow_debuff()
		player.apply_roar_shake(7.0, 2.0)
	
	await get_tree().create_timer(2.0).timeout
	is_invulnerable = false

# ==========================================
# FINAL (Terceiro Golpe)
# ==========================================
func trigger_finale():
	print("MORTE DA MATRIARCA!")
	roar_audio.play() # O rugido final
	
	if player:
		player.disable_for_cutscene()
		
	var canvas = CanvasLayer.new()
	var black_screen = ColorRect.new()
	black_screen.color = Color.BLACK
	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black_screen)
	add_child(canvas)
	
	# Corta todos os sons do jogo, MENOS o rugido
	heartbeat_audio.stop()
	boss_music.stop()
	# Aqui você pode acessar o Global para parar o som ambiente da caverna também
	
	var tween = create_tween()
	# Tela preta surge rápido
	tween.tween_property(black_screen, "modulate:a", 1.0, 0.5)
	
	await get_tree().create_timer(8.0).timeout
	
	
	get_tree().change_scene_to_file("res://scenes/credits.tscn")

# --- FUNÇÃO DE PRENDER O JOGADOR ---
func trap_player():
	if not cave_entrance_marker: return
	
	# Pega todos os monstros do mapa usando o grupo "enemy"
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		# Teleporta eles para a porta
		enemy.global_position = cave_entrance_marker.global_position
		
		# Opcional: Se eles tiverem a Máquina de Estados, force eles pro WANDER 
		# para eles ficarem patrulhando a entrada em vez de correrem pro coração
		if "current_state" in enemy:
			enemy.current_state = 0 # 0 é State.WANDER no seu script
