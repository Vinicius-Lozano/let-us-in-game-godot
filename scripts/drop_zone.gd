extends Area3D
class_name DropZone

# --- NOVO: O sinal que avisa o resto do jogo que a montagem terminou ---
signal item_assembled() 

@export_category("Drop Zone Settings")
@export var scenario_object: Node3D 
@export var expected_item_name: String = "" 

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if scenario_object:
		scenario_object.visible = false
		scenario_object.process_mode = Node.PROCESS_MODE_DISABLED

func _on_body_entered(body: Node3D) -> void:
	if "item_data" in body and body.item_data != null:
		if body.item_data.name == expected_item_name:
			assemble_item(body)

func assemble_item(physical_item: Node3D = null) -> void:
	if scenario_object:
		scenario_object.visible = true
		scenario_object.process_mode = Node.PROCESS_MODE_INHERIT
		
		var interact_comp = scenario_object.get_node_or_null("InteractionComponent")
		if interact_comp:
			interact_comp.can_interact = true
			
	if physical_item:
		physical_item.queue_free()
		
	var col_shape = get_node_or_null("CollisionShape3D")
	if col_shape:
		col_shape.set_deferred("disabled", true)
		
	# --- NOVO: Dispara o gatilho para os puzzles ---
	item_assembled.emit()
