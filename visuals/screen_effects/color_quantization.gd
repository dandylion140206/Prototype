class_name ColorQuantizationEffect
extends CanvasLayer

@onready var effect_rect: ColorRect = $EffectRect

var model := EffectModel.new("色量子化")
var _material: ShaderMaterial


func _ready() -> void:
	_material = effect_rect.material as ShaderMaterial

	model.add_parameter(
		EffectParameter.new(
			&"color_levels",
			"色段階",
			EffectParameter.Kind.INTEGER,
			8,
			2,
			32,
			1,
		)
	)

	model.add_parameter(
		EffectParameter.new(
			&"dither_enabled",
			"ディザリング",
			EffectParameter.Kind.BOOLEAN,
			true,
		)
	)

	model.add_parameter(
		EffectParameter.new(
			&"dither_strength",
			"ディザー強度",
			EffectParameter.Kind.FLOAT,
			1.0,
			0.0,
			1.0,
			0.05,
		)
	)

	model.parameter_changed.connect(_on_parameter_changed)
	model.enabled_changed.connect(_on_enabled_changed)

	_apply_initial_values()


func get_effect_model() -> EffectModel:
	return model


func _apply_initial_values() -> void:
	for parameter in model.parameters:
		_on_parameter_changed(
			parameter.id,
			model.get_value(parameter.id),
		)


func _on_parameter_changed(
	id: StringName,
	value: Variant,
) -> void:
	_material.set_shader_parameter(id, value)


func _on_enabled_changed(enabled: bool) -> void:
	effect_rect.visible = enabled
