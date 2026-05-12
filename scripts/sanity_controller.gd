#extends Node
#
#@onready var light_detection_viewport: SubViewport = %SubViewport
#@onready var light_detection: Node3D = %LightDetection
#@onready var debug: Label = %Debug
#@onready var distortion: Sprite2D = $Distortion
#@onready var distortion_material: ShaderMaterial = distortion.material
#@onready var player_camera: Camera3D = %Camera3D
#
#
#var light_level: float = 0.0
#var sanity: float = 100.0
#var time_since_sanity_change: float = 0.0
#const  SANITY_DRAIN_INTERVAL: float = 0.25
#const DARKNESS_THRESHOLD: float = 0.6
#const SANITY_REGEN_TARGET: float = 100.0
#const SANITY_REGEN_RATE: float = 1.0 / SANITY_DRAIN_INTERVAL
#
#
#func _ready() -> void:
	#light_detection_viewport.debug_draw = Viewport.DEBUG_DRAW_LIGHTING
#
#func _process(delta: float) -> void:
	#light_level = get_light_level()
	#
	#update_sanity(delta)
	#update_distortion(sanity)
	#
	#for enemy in get_tree().get_nodes_in_group("enemy"):
		#if is_enemy_on_screen(enemy):
			#if is_enemy_in_view(enemy, 10.0):
				#drain_sanity(delta * 8.0)
	#
	#debug.text = str("FPS: %d \nLight Level: %.2f \nSanity: %.2f") % [
		#Engine.get_frames_per_second(),
		#light_level,
		#sanity
	#]
#
#func get_light_level() -> float:
	#light_detection.global_position = get_parent().global_position
	#
	#var texture = light_detection_viewport.get_texture()
	#var color = get_average_color(texture)
	#
	#return color.get_luminance()
#
#func update_sanity(delta: float) -> void:
	#time_since_sanity_change += delta
	#
	#if light_level <= DARKNESS_THRESHOLD:
		#if time_since_sanity_change >= SANITY_DRAIN_INTERVAL and sanity > 0.0:
			#sanity -= 1.0
			#sanity = clamp(sanity, 0.0, 100.0)
			#time_since_sanity_change = 0.0
	#else:
		#if sanity < SANITY_REGEN_TARGET and light_level > 0.7:
			#if time_since_sanity_change >= SANITY_DRAIN_INTERVAL:
				#sanity += SANITY_REGEN_RATE * SANITY_DRAIN_INTERVAL
				#sanity = clamp(sanity, 0.0, SANITY_REGEN_TARGET)
				#time_since_sanity_change = 0.0
#
#func update_distortion(sanity: float) -> void:
	#var distortion: float = 0.0
	#if sanity < 50.0:
		#var t: float = (50.0 - sanity) / 50
		#t = pow(t, 2.5)
		#distortion = t * 0.05
	#
	#distortion_material.set_shader_parameter("distortion_strength", distortion)
#
#func is_enemy_on_screen(enemy: Node3D) -> bool:
	#var viewport: Viewport = player_camera.get_viewport()
	#var screen_size: Vector2 = viewport.size
	#
	#var enemy_position: Vector3 = enemy.global_transform.origin
	#var camera_position: Vector3 = player_camera.global_transform.origin
	#var to_enemy: Vector3 = enemy_position - camera_position
	#
	#var forward: Vector3 = -player_camera.global_basis.z
	#
	#if forward.dot(to_enemy) < 0.0:
		#return false
	#
	#var screen_pos: Vector2 = player_camera.unproject_position(enemy_position)
	#
	#if screen_pos.x < 0.0 or screen_pos.x > screen_size.x:
		#return false
	#if screen_pos.y < 0.0 or screen_pos.y > screen_size.y:
		#return false
	#
	#return true
#
#func is_enemy_in_view(enemy: Node3D, tolerance_degrees: float) -> bool:
	#var enemy_position: Vector3 = enemy.global_transform.origin
	#var camera_position: Vector3 = player_camera.global_transform.origin
	#
	#var to_enemy: Vector3 = (enemy_position - camera_position).normalized()
	#
	#var forward: Vector3 = -player_camera.global_basis.z
	#
	#var angle_deg: float = rad_to_deg(acos(forward.dot(to_enemy)))
	#
	#return angle_deg <= tolerance_degrees
#
#func drain_sanity(amount: float) -> void:
	#sanity -= amount
	#sanity = clamp(sanity, 0.0, 100.0)
#
#func add_sanity(amount: float) -> void:
	#sanity += amount
	#sanity = clamp(sanity, 0.0, 100.0)
#
#func get_average_color(texture: ViewportTexture) -> Color:
	#var image = texture.get_image()
	#image.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	#return image.get_pixel(0,0)
	
extends Node

@onready var light_detection_viewport: SubViewport = %SubViewport
@onready var light_detection: Node3D = %LightDetection
@onready var debug: Label = %Debug
@onready var player_camera: Camera3D = %Camera3D

@onready var border_overlay: TextureRect = $SanityUI/BorderOverlay
@onready var flash_overlay: TextureRect = $SanityUI/FlashOverlay

@export var border_textures: Array[Texture2D]
@export var flash_textures: Array[Texture2D]

var border_cycle_timer: float = 0.0
var flash_timer: float = 0.0
var current_border_index: int = 0

var vignette_material: ShaderMaterial
var light_level: float = 0.0
var sanity: float = 100.0
var time_since_sanity_change: float = 0.0
const SANITY_DRAIN_INTERVAL: float = 0.25
const DARKNESS_THRESHOLD: float = 0.6
const SANITY_REGEN_TARGET: float = 100.0
const SANITY_REGEN_RATE: float = 1.0 / SANITY_DRAIN_INTERVAL

func _ready() -> void:
	light_detection_viewport.debug_draw = Viewport.DEBUG_DRAW_LIGHTING
	border_overlay.modulate.a = 0.0
	flash_overlay.visible = false
	create_vignette_effect()

func create_vignette_effect():
	var color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float vignette_intensity = 0.0;
	void fragment() {
		float dist = distance(UV, vec2(0.5, 0.5)); // Distância até o centro da tela
		float alpha = smoothstep(0.2, 0.8, dist) * vignette_intensity; // Cria o degradê suave
		COLOR = vec4(0.0, 0.0, 0.0, alpha); // Pinta de preto com a transparência calculada
	}
	"""
	vignette_material = ShaderMaterial.new()
	vignette_material.shader = shader
	color_rect.material = vignette_material
	
	$SanityUI.add_child(color_rect)
	$SanityUI.move_child(color_rect, 0)

func _process(delta: float) -> void:
	light_level = get_light_level()
	
	update_sanity(delta)
	apply_sanity_effects(delta)
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_enemy_on_screen(enemy):
			if is_enemy_in_view(enemy, 10.0):
				if has_line_of_sight(enemy): 
					drain_sanity(delta * 8.0)
	
	debug.text = str("FPS: %d \nLight Level: %.2f \nSanity: %.2f") %[
		Engine.get_frames_per_second(),
		light_level,
		sanity
	]
func has_line_of_sight(enemy: Node3D) -> bool:
	var space_state = player_camera.get_world_3d().direct_space_state
	var camera_pos = player_camera.global_transform.origin
	var enemy_pos = enemy.global_transform.origin + Vector3(0, 1.0, 0)
	var query = PhysicsRayQueryParameters3D.create(camera_pos, enemy_pos)
	if get_parent() is CollisionObject3D:
		query.exclude = [get_parent().get_rid()]
		query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	
	if result:
		if result.collider == enemy:
			return true
		else:
			return false

	return true
	
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

func apply_sanity_effects(delta: float) -> void:
	if sanity < 50.0:
		var intensity: float = (50.0 - sanity) / 50.0
		
		var shake_amount = intensity * 0.05
		player_camera.h_offset = randf_range(-shake_amount, shake_amount)
		player_camera.v_offset = randf_range(-shake_amount, shake_amount)
		
		vignette_material.set_shader_parameter("vignette_intensity", intensity * 1.5)
		border_overlay.modulate.a = intensity 
		
		border_cycle_timer += delta
		if border_cycle_timer > 0.2:
			border_cycle_timer = 0.0
			if border_textures.size() > 0:
				current_border_index = (current_border_index + 1) % border_textures.size()
				border_overlay.texture = border_textures[current_border_index]
				
		flash_timer -= delta
		if flash_timer <= 0.0:
			if flash_textures.size() > 0:
				flash_overlay.texture = flash_textures.pick_random()
				flash_overlay.visible = true
				
				await get_tree().create_timer(0.1).timeout
				flash_overlay.visible = false
				
				flash_timer = randf_range(1.0, 5.0) - (intensity * 2.0)
				flash_timer = max(flash_timer, 0.5)
	else:
		player_camera.h_offset = 0.0
		player_camera.v_offset = 0.0
		border_overlay.modulate.a = 0.0
		flash_overlay.visible = false
		border_cycle_timer = 0.0
		flash_timer = 3.0
		if vignette_material:
			vignette_material.set_shader_parameter("vignette_intensity", 0.0)

func is_enemy_on_screen(enemy: Node3D) -> bool:
	var viewport: Viewport = player_camera.get_viewport()
	var screen_size: Vector2 = viewport.size
	var enemy_position: Vector3 = enemy.global_transform.origin
	var camera_position: Vector3 = player_camera.global_transform.origin
	var to_enemy: Vector3 = enemy_position - camera_position
	var forward: Vector3 = -player_camera.global_basis.z
	
	if forward.dot(to_enemy) < 0.0:
		return false
	var screen_pos: Vector2 = player_camera.unproject_position(enemy_position)
	if screen_pos.x < 0.0 or screen_pos.x > screen_size.x:
		return false
	if screen_pos.y < 0.0 or screen_pos.y > screen_size.y:
		return false
	return true

func is_enemy_in_view(enemy: Node3D, tolerance_degrees: float) -> bool:
	var enemy_position: Vector3 = enemy.global_transform.origin
	var camera_position: Vector3 = player_camera.global_transform.origin
	var to_enemy: Vector3 = (enemy_position - camera_position).normalized()
	var forward: Vector3 = -player_camera.global_basis.z
	var angle_deg: float = rad_to_deg(acos(forward.dot(to_enemy)))
	return angle_deg <= tolerance_degrees

func drain_sanity(amount: float) -> void:
	sanity -= amount
	sanity = clamp(sanity, 0.0, 100.0)

func add_sanity(amount: float) -> void:
	sanity += amount
	sanity = clamp(sanity, 0.0, 100.0)

func get_average_color(texture: ViewportTexture) -> Color:
	var image = texture.get_image()
	image.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	return image.get_pixel(0,0)
