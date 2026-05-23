extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_damage_area_body_entered(body: Node3D) -> void:
	var health_comp = body.get_node_or_null("HealthComponent")
	if health_comp:
		Global.killer_name = ""
		health_comp.take_damage(3)
