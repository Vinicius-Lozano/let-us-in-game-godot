extends GridContainer

var total_slots: int = 25
var slot_size: Vector2 = Vector2(40,40)

func _ready() -> void:
	for i in range(total_slots):
		create_slot()

func create_slot() -> void:
	var slot = ColorRect.new()
	
	slot.custom_minimum_size = slot_size
	
	slot.color = Color(0.2, 0.2, 0.2, 0.8)
	
	add_child(slot)
