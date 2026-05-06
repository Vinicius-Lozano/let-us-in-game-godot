extends Node

@onready var light_detection_viewport: SubViewport = %SubViewport
@onready var light_detection: Node3D = %LightDetection
@onready var debug: Label = %Debug
@onready var distortion: Sprite2D = $Distortion
@onready var distortion_material: ShaderMaterial = distortion.material

var light_level: float = 0.0
var sanity: float = 100.0
var time_since_sanity_change: float = 0.0
const  SANITY_DRAIN_INTERVAL: float = 0.25
const DARKNESS_THRESHOLD: float = 0.6
const SANITY_REGEN_TARGET: float = 100.0
const SANITY_REGEN_RATE: float = 1.0 / SANITY_DRAIN_INTERVAL


func _ready() -> void:
	light_detection_viewport.debug_draw = Viewport.DEBUG_DRAW_LIGHTING

func _process(delta: float) -> void:
	light_level = get_light_level()
	
	update_sanity(delta)
	update_distortion(sanity)
	
	debug.text = str("FPS: %d \nLight Level: %.2f \nSanity: %.2f") % [
		Engine.get_frames_per_second(),
		light_level,
		sanity
	]

func get_light_level() -> float:
	light_detection.global_position = get_parent().global_position
	
	var texture = light_detection_viewport.get_texture()
	var color = get_average_color(texture)
	
	return color.get_luminance()

func update_sanity(delta: float) -> void:
	time_since_sanity_change += delta
	
	if light_level <= DARKNESS_THRESHOLD:
		if time_since_sanity_change >= SANITY_DRAIN_INTERVAL and sanity > 0.0:
			sanity -= 1.0
			sanity = clamp(sanity, 0.0, 100.0)
			time_since_sanity_change = 0.0
	else:
		if sanity < SANITY_REGEN_TARGET and light_level > 0.7:
			if time_since_sanity_change >= SANITY_DRAIN_INTERVAL:
				sanity += SANITY_REGEN_RATE * SANITY_DRAIN_INTERVAL
				sanity = clamp(sanity, 0.0, SANITY_REGEN_TARGET)
				time_since_sanity_change = 0.0

func update_distortion(sanity: float) -> void:
	var distortion: float = 0.0
	if sanity < 50.0:
		var t: float = (50.0 - sanity) / 50
		t = pow(t, 2.5)
		distortion = t * 0.05
	
	distortion_material.set_shader_parameter("distortion_strength", distortion)


func get_average_color(texture: ViewportTexture) -> Color:
	var image = texture.get_image()
	image.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	return image.get_pixel(0,0)
