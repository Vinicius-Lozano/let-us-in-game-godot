extends ActionData
class_name EquippableAction

@export var one_time_use: bool = true
@export var success_text: String = 'Success'

func _init() -> void:
	action_type = ActionType.EQUIPPABLE
