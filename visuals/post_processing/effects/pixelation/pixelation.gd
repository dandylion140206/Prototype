@tool
class_name Pixelation
extends PostProcessEffect

const EFFECT_SHADER: Shader = preload("./pixelation.gdshader")

@export var enabled: bool = true:
	set(value):
		if enabled == value:
			return

		enabled = value
		notify_change()

@export_range(1, 32, 1) var pixel_size: int = 4:
	set(value):
		if pixel_size == value:
			return

		pixel_size = value
		notify_change()


func _get_shader() -> Shader:
	return EFFECT_SHADER


func _update_shader_parameters() -> void:
	shader_parameters[&"pixel_size"] = pixel_size
