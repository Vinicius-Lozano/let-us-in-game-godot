extends ColorRect

@onready var grid: GridContainer = $"../SlotGrid"
var current_index: int = 0

func _ready() -> void:
	await get_tree().process_frame
	global_position = grid.get_child(current_index).global_position

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_left"):
		current_index -= 1
	if event.is_action_pressed("ui_right"):
		current_index += 1
	if event.is_action_pressed("ui_up") and current_index >= grid.columns:
		current_index -= 5
	if event.is_action_pressed("ui_down") and current_index < grid.total_slots - 5:
		current_index += 5
	current_index = clamp(current_index, 0, grid.total_slots-1)
	global_position = grid.get_child(current_index).global_position
