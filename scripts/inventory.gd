extends Node

signal inventory_updated
var is_open: bool = false

var items: Array[ItemData] = []

func add_item(item: ItemData):
	items.append(item)
	inventory_updated.emit()

func remove_item(item: ItemData):
	item.erase(item)
	inventory_updated.emit()
