class_name ColorQuantizationEffect
extends CanvasLayer

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

@onready var effect_rect: ColorRect = $EffectRect

var model := EffectModel.new("Color Quantization")
var _material: ShaderMaterial


func _ready() -> void:
	_material = effect_rect.material as ShaderMaterial

	_add_quantization_parameters()
	_add_dither_parameters()

	model.parameter_changed.connect(_on_parameter_changed)
	model.enabled_changed.connect(_on_enabled_changed)
	_apply_initial_values()


func get_effect_model() -> EffectModel:
	return model


func _add_quantization_parameters() -> void:
	var quantization_mode := EffectParameter.new(
		&"quantization_mode",
		"RGB Level Mode",
		EffectParameter.Kind.ENUM,
		QuantizationMode.SHARED,
	)
	quantization_mode.set_options(
		["Shared", "Per Channel"]
	)
	model.add_parameter(quantization_mode)

	var color_space := EffectParameter.new(
		&"color_space",
		"Color Space",
		EffectParameter.Kind.ENUM,
		ColorSpace.SRGB,
	)
	color_space.set_options(
		["sRGB", "Linear"]
	)
	model.add_parameter(color_space)

	var color_levels := EffectParameter.new(
		&"color_levels",
		"Color Levels",
		EffectParameter.Kind.INTEGER,
		8,
	)
	color_levels.set_range(2, 32, 1)
	color_levels.set_visibility_condition(
		&"quantization_mode",
		[QuantizationMode.SHARED],
	)
	model.add_parameter(color_levels)

	for data in [
		[&"red_levels", "Red Levels"],
		[&"green_levels", "Green Levels"],
		[&"blue_levels", "Blue Levels"],
	]:
		var parameter := EffectParameter.new(
			data[0],
			data[1],
			EffectParameter.Kind.INTEGER,
			8,
		)
		parameter.set_range(2, 32, 1)
		parameter.set_visibility_condition(
			&"quantization_mode",
			[QuantizationMode.PER_CHANNEL],
		)
		model.add_parameter(parameter)


func _add_dither_parameters() -> void:
	var dither_enabled := EffectParameter.new(
		&"dither_enabled",
		"Dithering",
		EffectParameter.Kind.BOOLEAN,
		true,
	)
	model.add_parameter(dither_enabled)

	var dither_mode := EffectParameter.new(
		&"dither_mode",
		"Dither Mode",
		EffectParameter.Kind.ENUM,
		DitherMode.BAYER_4X4,
	)
	dither_mode.set_options(
		["Bayer 2×2", "Bayer 4×4", "Bayer 8×8", "IGN"]
	)
	dither_mode.set_visibility_condition(
		&"dither_enabled",
		[true],
	)
	model.add_parameter(dither_mode)

	var dither_strength := EffectParameter.new(
		&"dither_strength",
		"Dither Strength",
		EffectParameter.Kind.FLOAT,
		1.0,
	)
	dither_strength.set_range(0.0, 1.0, 0.05)
	dither_strength.set_visibility_condition(
		&"dither_enabled",
		[true],
	)
	model.add_parameter(dither_strength)

	var dither_scale := EffectParameter.new(
		&"dither_scale",
		"Dither Scale",
		EffectParameter.Kind.INTEGER,
		1,
	)
	dither_scale.set_range(1, 8, 1)
	dither_scale.set_visibility_condition(
		&"dither_enabled",
		[true],
	)
	model.add_parameter(dither_scale)


func _apply_initial_values() -> void:
	for parameter in model.parameters:
		_on_parameter_changed(parameter.id, model.get_value(parameter.id))


func _on_parameter_changed(id: StringName, value: Variant) -> void:
	_material.set_shader_parameter(id, value)


func _on_enabled_changed(enabled: bool) -> void:
	effect_rect.visible = enabled
