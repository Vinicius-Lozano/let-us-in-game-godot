extends Node
class_name InventoryController

@onready var canvas: CanvasLayer = $CanvasLayer
@onready var grid: GridContainer = $CanvasLayer/InventoryUI/Panel/MarginContainer/GridContainer
@onready var context_menu: PopupMenu = PopupMenu.new()

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
	
	# PopupMenu
	add_child(context_menu)
	context_menu.connect('id_pressed', Callable(self, "_on_context_menu_selected"))
	
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
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			#use_collectable
			print("I eat a ball")
		ActionData.ActionType.EQUIPPABLE:
			#equipped_collectable
			print("I'm holding a block")
		ActionData.ActionType.INSPECTABLE:
			#inspect_collectable
			print("I'm looking at it, It's a prism")
	context_menu.set_meta('slot_id', slot_id)

func _on_item_right_clicked(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	context_menu.clear()
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			context_menu.add_item("Use", 0)
			context_menu.add_item("Drop", 1)
		ActionData.ActionType.EQUIPPABLE:
			context_menu.add_item("Equip", 0)
			context_menu.add_item("Drop", 1)
		ActionData.ActionType.INSPECTABLE:
			context_menu.add_item("View", 0)
			context_menu.add_item("Drop", 1)
	context_menu.set_meta('slot_id', slot_id)
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var rect: Rect2i = Rect2i(mouse_pos.floor(), Vector2i(1,1))
	context_menu.popup(rect)
	
func _on_context_menu_selected(id: int) -> void:
	var slot_id = context_menu.get_meta('slot_id')
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			match id:
				0: #use_collectable
					print("I eat a ball")
				1: #drop_collectable
					print("Drop the thing")
		ActionData.ActionType.EQUIPPABLE:
			match id:
				0: #equipped_collectable
					print("I'm holding a block")
				1: #drop_collectable
					print("Drop the thing")
		ActionData.ActionType.INSPECTABLE:
			match id:
				0: #inspect_collectable
					print("I'm looking at it, It's a prism")
				1: #drop_collectable
					print("Drop the thing")
	
func _get_item_action_type(item_data: ItemData) -> ActionData.ActionType:
	if not item_data or not item_data.item_model_prefab == null:
		return ActionData.ActionType.INVALID
		
	return item_data.action_data.action_type
