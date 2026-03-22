extends Node
class_name InventoryController

@onready var canvas: CanvasLayer = $CanvasLayer
@onready var grid: GridContainer = $CanvasLayer/InventoryUI/Panel/MarginContainer/GridContainer

var item_slots_count: int = 18
var inventory_slot_prefab: PackedScene = load("res://scenes/inventory_slot.tscn")
var inventory_slots: Array[InventorySlot] = []
var inventory_full: bool = false

func _ready() -> void:
	# Inventory visibility toggle 
	canvas.visible = false
	Inventory.is_open = false
	
	# populate Inventory Grid
	for i in item_slots_count:
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		grid.add_child(slot)
		slot.inventory_slot_id = i
		slot.on_item_swapped.connect(_on_item_swapped_on_slot)
		slot.on_item_double_clicked.connect(_on_item_double_clicked)
		slot.on_item_right_clicked.connect(_on_item_right_clicked)
		inventory_slots.append(slot)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('toggle_inventory'):
		canvas.visible = not canvas.visible
		Inventory.is_open = canvas.visible
		
	if canvas.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func has_free_slot() -> bool:
	for slot in inventory_slots:
		if slot.slot_data == null:
			return true
	return false

func pickup_item(item_data: ItemData) -> void:
	for slot in inventory_slots:
		if not slot.slot_filled:
			slot.fill_slot(item_data)
			inventory_full = not has_free_slot()
			return
	inventory_full = true

func _on_item_swapped_on_slot(from_slot_id: int, to_slot_id: int) -> void:
	var to_slot_item: ItemData = inventory_slots[to_slot_id].slot_data
	var from_slot_item: ItemData = inventory_slots[from_slot_id].slot_data
	inventory_slots[to_slot_id].fill_slot(from_slot_item)
	inventory_slots[from_slot_id].fill_slot(to_slot_item)
	
func _on_item_double_clicked(slot_id: int) -> void:
	return

func _on_item_right_clicked(slot_id: int) -> void:
	return
