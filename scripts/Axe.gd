extends TextureRect

@onready var swing_audio = $SwingSound
@onready var hit_audio = $HitSound
@onready var enemy_hit = $EnemyHitSound

@export var raycast: RayCast3D 
var can_attack: bool = true

func _ready():
	if raycast != null:
		raycast.add_exception(owner)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("atacar"):
		if can_attack:
			swing_axe()

func swing_axe():
	can_attack = false
	swing_audio.play()
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", deg_to_rad(-60), 0.15)
	tween.tween_property(self, "rotation", 0.0, 0.25)
	
	if raycast != null and raycast.is_colliding():
		var target = raycast.get_collider()
		hit_audio.play()
		# ISSO VAI TE AJUDAR A DESCOBRIR O ERRO:
		# Olhe o painel "Output" (Saída) embaixo da tela do Godot quando atacar!
		print("O machado bateu em: ", target.name) 
		
		if target.has_method("take_hit"):
			print("Inimigo atordoado")
			target.take_hit()
			enemy_hit.play()
		else:
			print("O alvo não tem a função 'take_hit'.")
			
	await get_tree().create_timer(0.5).timeout
	can_attack = true
