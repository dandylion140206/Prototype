class_name EffectModel
extends RefCounted

signal parameter_changed(id: StringName, value: Variant)
signal enabled_changed(enabled: bool)

var display_name: String
var parameters: Array[EffectParameter] = []

var enabled := true:
	set(value):
		if enabled == value:
			return

		enabled = value
		enabled_changed.emit(enabled)

var _parameters_by_id: Dictionary[StringName, EffectParameter] = {}
var _values: Dictionary[StringName, Variant] = {}


func _init(model_display_name: String = "") -> void:
	display_name = model_display_name


func add_parameter(parameter: EffectParameter) -> void:
	if parameter.id == &"":
		push_warning("Effect parameter ID must not be empty.")
		return

	if _parameters_by_id.has(parameter.id):
		push_warning("Duplicate effect parameter: %s" % parameter.id)
		return

	parameter.default_value = parameter.normalize_value(
		parameter.default_value
	)

	parameters.append(parameter)
	_parameters_by_id[parameter.id] = parameter
	_values[parameter.id] = parameter.default_value


func has_parameter(parameter_id: StringName) -> bool:
	return _parameters_by_id.has(parameter_id)


func get_parameter(parameter_id: StringName) -> EffectParameter:
	if not _parameters_by_id.has(parameter_id):
		push_warning("Unknown effect parameter: %s" % parameter_id)
		return null

	return _parameters_by_id[parameter_id]


func get_value(parameter_id: StringName) -> Variant:
	if not _values.has(parameter_id):
		push_warning("Unknown effect parameter: %s" % parameter_id)
		return null

	return _values[parameter_id]


func set_value(parameter_id: StringName, value: Variant) -> void:
	var parameter := get_parameter(parameter_id)
	if parameter == null:
		return

	var normalized_value: Variant = parameter.normalize_value(value)
	if _values[parameter_id] == normalized_value:
		return

	_values[parameter_id] = normalized_value
	parameter_changed.emit(parameter_id, normalized_value)


func reset_parameter(parameter_id: StringName) -> void:
	var parameter := get_parameter(parameter_id)
	if parameter == null:
		return

	set_value(parameter_id, parameter.default_value)


func reset_all_parameters() -> void:
	for parameter in parameters:
		reset_parameter(parameter.id)


func is_parameter_visible(parameter_id: StringName) -> bool:
	var parameter := get_parameter(parameter_id)
	if parameter == null:
		return false

	if parameter.visibility_parameter == &"":
		return true

	if not _values.has(parameter.visibility_parameter):
		push_warning(
			"Unknown visibility parameter '%s' referenced by '%s'."
			% [parameter.visibility_parameter, parameter.id]
		)
		return false

	return parameter.is_visible_for(
		_values[parameter.visibility_parameter]
	)
