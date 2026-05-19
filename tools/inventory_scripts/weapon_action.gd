extends ActionData
class_name WeaponAction

@export var damage: int = 10 # Já deixando preparado para o futuro!

func _init() -> void:
	action_type = ActionType.WEAPON
