extends Node3D

@export var raycast: RayCast3D 

# --- NOVO: O machado não sabe o que é um Resource. Ele só guarda um número. ---
var current_damage: int = 1
# -----------------------------------------------------------------------------

var can_attack: bool = false
var is_swinging: bool = false

@onready var swing_sound = $SwingSound
@onready var hit_generic = $HitSound
@onready var hit_monster = $EnemyHitSound

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if visible and can_attack and Input.is_action_just_pressed("atacar") and not is_swinging:
		swing_axe()

func swing_axe() -> void:
	is_swinging = true
	swing_sound.pitch_scale = randf_range(0.9, 1.1)
	swing_sound.play()
	
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", Vector3(0, 30, 10), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation_degrees", Vector3.ZERO, 0.2)
	
	if raycast != null and raycast.is_colliding():
		var target = raycast.get_collider()
		var health_comp = target.get_node_or_null("HealthComponent")
		
		if health_comp:
			hit_monster.pitch_scale = randf_range(0.9, 1.1)
			hit_monster.play()
			
			# --- NOVO: Aplica o dano que foi injetado na hora de equipar! ---
			health_comp.take_damage(current_damage)
		else:
			hit_generic.pitch_scale = randf_range(0.8, 1.2)
			hit_generic.play()
			
		if target.has_method("take_hit"):
			target.take_hit()
			
	await tween.finished
	is_swinging = false

# --- NOVO: A função equip agora exige que digam a ela qual o dano atual ---
func equip(weapon_damage: int) -> void:
	current_damage = weapon_damage
	visible = true
	can_attack = true

func unequip() -> void:
	visible = false
	can_attack = false
	is_swinging = false
