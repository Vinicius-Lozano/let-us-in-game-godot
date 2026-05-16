extends Area3D

@export_category("Receptacle Settings")
@export var scenario_crank: Node3D 

# Nome exato que você colocou no ItemData da Manivela
@export var expected_item_name: String = "Crank" 

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if scenario_crank:
		scenario_crank.visible = false

func _on_body_entered(body: Node3D) -> void:
	# 1. Verifica se o corpo tem a variável item_data
	if "item_data" in body and body.item_data != null:
		
		# 2. Verifica se o nome do item bate com o que o buraco espera
		if body.item_data.name == expected_item_name:
			assemble_crank(body)

func assemble_crank(physical_item: Node3D = null) -> void:
	# Ativa a manivela do cenário
	if scenario_crank:
		scenario_crank.visible = true
		
		var interact_comp = scenario_crank.get_node_or_null("InteractionComponent")
		if interact_comp:
			interact_comp.can_interact = true
			
	# Se um item físico foi passado (arrastado), destruímos ele
	if physical_item:
		physical_item.queue_free()
		
	# Desativa esta área para não repetir
	queue_free()
