extends ActionData
class_name FlashlightAction

@export var time_to_respawn: float = 6.0

func _init() -> void:
	action_type = ActionType.FLASHLIGHT
