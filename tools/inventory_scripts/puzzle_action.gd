extends ActionData
class_name PuzzleAction

@export var target_receptacle_id: String = "crank_hole_1" 
@export var success_message: String = "Item encaixado com sucesso."

func _init() -> void:
	action_type = ActionType.PUZZLE
