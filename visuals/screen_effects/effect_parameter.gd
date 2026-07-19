class_name EffectParameter
extends RefCounted

enum Kind {
	INTEGER,
	FLOAT,
	BOOLEAN,
	ENUM,
}

var id: StringName
var display_name: String
var kind: Kind
var default_value: Variant

var min_value := 0.0
var max_value := 1.0
var step := 0.01
var options: Array = []

var visibility_parameter: StringName
var visibility_values: Array = []


func _init(
	parameter_id: StringName,
	parameter_display_name: String,
	parameter_kind: Kind,
	parameter_default_value: Variant,
) -> void:
	id = parameter_id
	display_name = parameter_display_name
	kind = parameter_kind
	default_value = parameter_default_value


func set_range(
	minimum: float,
	maximum: float,
	value_step: float,
) -> void:
	if not is_numeric():
		push_warning(
			"Only numeric parameters can have a range: %s"
			% id
		)
		return

	min_value = minimum
	max_value = maximum
	step = value_step


func set_options(parameter_options: Array) -> void:
	if kind != Kind.ENUM:
		push_warning(
			"Only enum parameters can have options: %s"
			% id
		)
		return

	options = parameter_options.duplicate()


func set_visibility_condition(
	condition_parameter: StringName,
	condition_values: Array,
) -> void:
	visibility_parameter = condition_parameter
	visibility_values = condition_values.duplicate()


func is_numeric() -> bool:
	return kind == Kind.INTEGER or kind == Kind.FLOAT


func is_visible_for(value: Variant) -> bool:
	if visibility_parameter == &"":
		return true

	return visibility_values.has(value)


func normalize_value(value: Variant) -> Variant:
	match kind:
		Kind.INTEGER:
			return clampi(
				roundi(float(value)),
				ceili(min_value),
				floori(max_value),
			)

		Kind.FLOAT:
			return clampf(float(value), min_value, max_value)

		Kind.BOOLEAN:
			return bool(value)

		Kind.ENUM:
			if options.is_empty():
				return -1

			return clampi(int(value), 0, options.size() - 1)

	return value
