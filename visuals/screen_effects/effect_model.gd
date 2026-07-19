class_name EffectModel
extends RefCounted


signal parameter_changed(id: StringName, value: Variant)
signal enabled_changed(enabled: bool)


var display_name: String
var parameters: Array[EffectParameter] = []
var enabled: bool = true:
	set(value):
		if enabled == value:
			return

		enabled = value
		enabled_changed.emit(enabled)

var _values: Dictionary = {}


func _init(model_display_name: String = "") -> void:
	display_name = model_display_name


func add_parameter(parameter: EffectParameter) -> void:
	parameters.append(parameter)
	_values[parameter.id] = parameter.default_value


func get_value(id: StringName) -> Variant:
	return _values.get(id)


func set_value(id: StringName, value: Variant) -> void:
	if not _values.has(id):
		push_warning("Unknown effect parameter: %s" % id)
		return

	if _values[id] == value:
		return

	_values[id] = value
	parameter_changed.emit(id, value)
