class_name EffectParameterDefinition
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

var options: PackedStringArray
var option_values: Array[int] = []


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
			var enum_value := int(value)

			if option_values.has(enum_value):
				return enum_value

			push_warning("Invalid enum value '%s' for '%s'." % [enum_value, id])
			return default_value

	assert(false, "Unsupported effect parameter kind: %s" % kind)
	return value


func get_option_index(value: int) -> int:
	return option_values.find(value)
