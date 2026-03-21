extends CanvasLayer
var inventory_state = false

func _ready() -> void:
	visible = false
	Inventory.is_open = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('toggle_inventory'):
		visible = not visible
		Inventory.is_open = visible
		
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
