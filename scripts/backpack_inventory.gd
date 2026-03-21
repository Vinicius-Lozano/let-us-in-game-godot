extends Panel
@onready var grid_container: GridContainer = $GridContainer

var data_bk
func _ready() -> void:
	Inventory.inventory_updated.connect(populate)
	populate()

func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_DRAG_BEGIN:
		data_bk = get_viewport().gui_get_drag_data()
	if what == Node.NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			if data_bk:
				data_bk.icon.show()
				data_bk = null

func populate():
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		
		if i < Inventory.items.size():
			slot.item = Inventory.items[i]
		else:
			slot.item = null
			
		slot.update_ui()
