class_name ScreenEffectState
extends RefCounted

signal parameter_changed(id: StringName, value: Variant)
signal enabled_changed(enabled: bool)

var display_name: String
var parameters: Array[ScreenEffectParameterDefinition] = []

var enabled := true:
	set(value):
		if enabled == value:
			return

		enabled = value
		enabled_changed.emit(enabled)

var _activation_rules: Array[ScreenEffectParameterActivationRule] = []
var _parameters_by_id: Dictionary[StringName, ScreenEffectParameterDefinition] = {}
var _values: Dictionary[StringName, Variant] = {}


func _init(definition: ScreenEffectDefinition) -> void:
	assert(definition != null, "ScreenEffectDefinition must not be null")
	assert(definition.shader != null, "Screen effect shader must not be null")

	display_name = definition.display_name
	enabled = definition.enabled_by_default
	parameters = ScreenEffectParameterReader.read_all(definition.shader)
	_activation_rules = definition.activation_rules.duplicate()

	var parameter_ids: Dictionary[StringName, bool] = {}

	for parameter in parameters:
		assert(not parameter_ids.has(parameter.id), "Duplicate effect parameter: %s" % parameter.id)

		parameter_ids[parameter.id] = true
		_parameters_by_id[parameter.id] = parameter
		_values[parameter.id] = parameter.default_value

	definition.validate(parameter_ids)


func has_parameter(parameter_id: StringName) -> bool:
	return _parameters_by_id.has(parameter_id)


func get_parameter(parameter_id: StringName) -> ScreenEffectParameterDefinition:
	assert(_parameters_by_id.has(parameter_id), "Unknown effect parameter: %s" % parameter_id)
	return _parameters_by_id[parameter_id]


func get_value(parameter_id: StringName) -> Variant:
	assert(_values.has(parameter_id), "Unknown effect parameter: %s" % parameter_id)
	return _values[parameter_id]


func set_value(parameter_id: StringName, value: Variant) -> void:
	var parameter := get_parameter(parameter_id)
	var normalized_value: Variant = parameter.normalize_value(value)

	if _values[parameter_id] == normalized_value:
		return

	_values[parameter_id] = normalized_value
	parameter_changed.emit(parameter_id, normalized_value)


func is_parameter_active(parameter_id: StringName) -> bool:
	assert(has_parameter(parameter_id), "Unknown effect parameter: %s" % parameter_id)

	for rule in _activation_rules:
		if not rule.target_parameters.has(parameter_id):
			continue

		var condition_value: Variant = get_value(rule.condition_parameter)

		if not rule.is_active(condition_value):
			return false

	return true
