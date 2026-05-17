extends TextureRect

@export var raycast: RayCast3D 
var can_attack: bool = true

func _ready():
	# ISSO É VITAL: Faz o raio ignorar o corpo do próprio jogador!
	# (O "owner" é o nó principal da cena, que é o seu CharacterBody3D do Jogador)
	if raycast != null:
		raycast.add_exception(owner)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if can_attack:
			swing_axe()

func swing_axe():
	can_attack = false
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", deg_to_rad(-60), 0.15)
	tween.tween_property(self, "rotation", 0.0, 0.25)
	
	if raycast != null and raycast.is_colliding():
		var target = raycast.get_collider()
		
		# ISSO VAI TE AJUDAR A DESCOBRIR O ERRO:
		# Olhe o painel "Output" (Saída) embaixo da tela do Godot quando atacar!
		print("O machado bateu em: ", target.name) 
		
		if target.has_method("take_hit"):
			print("Sucesso! Inimigo atordoado!")
			target.take_hit()
		else:
			print("O alvo não tem a função 'take_hit'.")
			
	await get_tree().create_timer(0.5).timeout
	can_attack = true
