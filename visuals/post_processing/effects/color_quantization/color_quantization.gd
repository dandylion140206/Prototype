@tool
class_name ColorQuantization
extends PostProcessEffect

enum QuantizationMode {
	SHARED,
	PER_CHANNEL,
}

enum ColorSpace {
	SRGB,
	LINEAR,
}

enum DitherMode {
	BAYER_2X2,
	BAYER_4X4,
	BAYER_8X8,
	IGN,
}

const EFFECT_SHADER: Shader = preload("./color_quantization.gdshader")

@export var quantization_mode: QuantizationMode = QuantizationMode.SHARED:
	set(value):
		if quantization_mode == value:
			return

		quantization_mode = value
		notify_change()

@export var color_space: ColorSpace = ColorSpace.SRGB:
	set(value):
		if color_space == value:
			return

		color_space = value
		notify_change()

@export_range(2, 32, 1) var color_levels: int = 8:
	set(value):
		if color_levels == value:
			return

		color_levels = value
		notify_change()

@export_range(2, 32, 1) var red_levels: int = 8:
	set(value):
		if red_levels == value:
			return

		red_levels = value
		notify_change()

@export_range(2, 32, 1) var green_levels: int = 8:
	set(value):
		if green_levels == value:
			return

		green_levels = value
		notify_change()

@export_range(2, 32, 1) var blue_levels: int = 8:
	set(value):
		if blue_levels == value:
			return

		blue_levels = value
		notify_change()

@export var dither_enabled: bool = true:
	set(value):
		if dither_enabled == value:
			return

		dither_enabled = value
		notify_change()

@export var dither_mode: DitherMode = DitherMode.BAYER_4X4:
	set(value):
		if dither_mode == value:
			return

		dither_mode = value
		notify_change()

@export_range(0.0, 1.0, 0.05) var dither_strength: float = 1.0:
	set(value):
		if is_equal_approx(dither_strength, value):
			return

		dither_strength = value
		notify_change()

@export_range(1, 8, 1) var dither_scale: int = 1:
	set(value):
		if dither_scale == value:
			return

		dither_scale = value
		notify_change()


func _get_shader() -> Shader:
	return EFFECT_SHADER


func _update_shader_parameters() -> void:
	shader_parameters[&"quantization_mode"] = quantization_mode
	shader_parameters[&"color_space"] = color_space
	shader_parameters[&"color_levels"] = color_levels
	shader_parameters[&"red_levels"] = red_levels
	shader_parameters[&"green_levels"] = green_levels
	shader_parameters[&"blue_levels"] = blue_levels
	shader_parameters[&"dither_enabled"] = dither_enabled
	shader_parameters[&"dither_mode"] = dither_mode
	shader_parameters[&"dither_strength"] = dither_strength
	shader_parameters[&"dither_scale"] = dither_scale
