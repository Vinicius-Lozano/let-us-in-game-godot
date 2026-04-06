extends SpotLight3D

@export var actuation_percentage: float = 0.8

func execute(_percentage: float) -> void:
	if _percentage < actuation_percentage:
		visible = false
	else:
		visible = true
