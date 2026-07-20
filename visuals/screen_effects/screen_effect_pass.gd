class_name ScreenEffectPass
extends Control

@export var definition: ScreenEffectDefinition

var state: ScreenEffectState

@onready var _full_screen_rect: ColorRect = $FullScreenRect

var _material: ShaderMaterial


func _ready() -> void:
	assert(definition != null, "ScreenEffectDefinition must not be null")
	assert(definition.shader != null, "Screen effect shader must not be null")
	assert(_full_screen_rect != null, "FullScreenRect must not be null")

	_material = ShaderMaterial.new()
	_material.shader = definition.shader
	_full_screen_rect.material = _material

	state = ScreenEffectState.new(definition)
	state.parameter_changed.connect(_on_parameter_changed)
	state.enabled_changed.connect(_on_enabled_changed)

	for parameter in state.parameters:
		_apply_parameter(parameter.id, state.get_value(parameter.id))

	_on_enabled_changed(state.enabled)


func _on_parameter_changed(id: StringName, value: Variant) -> void:
	_apply_parameter(id, value)


func _on_enabled_changed(enabled: bool) -> void:
	visible = enabled


func _apply_parameter(id: StringName, value: Variant) -> void:
	assert(_material != null, "ShaderMaterial must be initialized")
	_material.set_shader_parameter(id, value)
