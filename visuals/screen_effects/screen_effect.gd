class_name ScreenEffect
extends CanvasLayer

@export var definition: ScreenEffectDefinition

var model: EffectModel

@onready var _effect_rect: ColorRect = $EffectRect

var _material: ShaderMaterial


func _ready() -> void:
	assert(definition != null, "ScreenEffectDefinition must not be null")
	assert(definition.shader != null, "Screen effect shader must not be null")
	assert(_effect_rect != null, "EffectRect must not be null")

	_material = ShaderMaterial.new()
	_material.shader = definition.shader
	_effect_rect.material = _material

	model = EffectModel.new(definition)
	model.parameter_changed.connect(_on_parameter_changed)
	model.enabled_changed.connect(_on_enabled_changed)

	for parameter in model.parameters:
		_apply_parameter(parameter.id, model.get_value(parameter.id))

	_on_enabled_changed(model.enabled)


func _on_parameter_changed(id: StringName, value: Variant) -> void:
	_apply_parameter(id, value)


func _on_enabled_changed(enabled: bool) -> void:
	_effect_rect.visible = enabled


func _apply_parameter(id: StringName, value: Variant) -> void:
	assert(_material != null, "ShaderMaterial must be initialized")
	_material.set_shader_parameter(id, value)
