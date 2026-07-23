class_name ScreenEffectParameterReader

extends RefCounted


const SHADER_FLOAT_SIGNIFICANT_DIGITS := 7


static func read_all(shader: Shader) -> Array[ScreenEffectParameterDefinition]:
	assert(shader != null, "Shader must not be null")

	var shader_rid := shader.get_rid()
	var parameters: Array[ScreenEffectParameterDefinition] = []

	for uniform_data: Dictionary in shader.get_shader_uniform_list():
		var parameter := _read_parameter(uniform_data, shader_rid)

		if parameter != null:
			parameters.append(parameter)

	return parameters


static func _read_parameter(
	uniform_data: Dictionary,
	shader_rid: RID,
) -> ScreenEffectParameterDefinition:
	if not uniform_data.has("name") or not uniform_data.has("type"):
		return null

	var parameter_id := StringName(uniform_data["name"])
	var uniform_type := int(uniform_data["type"])
	var hint := int(uniform_data.get("hint", PROPERTY_HINT_NONE))
	var hint_string := String(uniform_data.get("hint_string", ""))

	var parameter := ScreenEffectParameterDefinition.new()
	parameter.id = parameter_id
	parameter.display_name = String(parameter_id).capitalize()

	match uniform_type:
		TYPE_BOOL:
			parameter.kind = ScreenEffectParameterDefinition.Kind.BOOLEAN

		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				parameter.kind = ScreenEffectParameterDefinition.Kind.ENUM
				_apply_enum_hint(parameter, hint_string)
			else:
				parameter.kind = ScreenEffectParameterDefinition.Kind.INTEGER
				_apply_range_hint(parameter, hint, hint_string)

		TYPE_FLOAT:
			parameter.kind = ScreenEffectParameterDefinition.Kind.FLOAT
			_apply_range_hint(parameter, hint, hint_string)

		TYPE_OBJECT:
			return null

		TYPE_VECTOR2:
			return null

		TYPE_COLOR:
			parameter.kind = ScreenEffectParameterDefinition.Kind.COLOR

		_:
			push_warning("Unsupported shader parameter type '%s': %s" % [uniform_type, parameter_id])
			return null

	parameter.default_value = RenderingServer.shader_get_parameter_default(shader_rid, parameter_id)

	assert(
		parameter.default_value != null,
		"Shader parameter default value is null: %s" % parameter_id
	)

	parameter.default_value = parameter.normalize_value(parameter.default_value)

	if parameter.kind == ScreenEffectParameterDefinition.Kind.ENUM:
		assert(
			parameter.option_values.has(int(parameter.default_value)),
			"Enum default value is not included in options: %s" % parameter.id,
		)

	return parameter


static func _apply_range_hint(
	parameter: ScreenEffectParameterDefinition,
	hint: int,
	hint_string: String,
) -> void:
	assert(
		hint == PROPERTY_HINT_RANGE,
		"Numeric shader parameter requires hint_range: %s" % parameter.id
	)

	var range_parts := hint_string.split(",")

	assert(range_parts.size() >= 2, "Invalid hint_range: %s" % parameter.id)

	parameter.min_value = _clean_shader_float(range_parts[0].to_float())
	parameter.max_value = _clean_shader_float(range_parts[1].to_float())

	if range_parts.size() >= 3:
		parameter.step = _clean_shader_float(range_parts[2].to_float())
	elif parameter.kind == ScreenEffectParameterDefinition.Kind.INTEGER:
		parameter.step = 1.0
	else:
		parameter.step = 0.01

	assert(parameter.min_value <= parameter.max_value, "Invalid parameter range: %s" % parameter.id)
	assert(parameter.step > 0.0, "Parameter step must be greater than zero: %s" % parameter.id)


static func _clean_shader_float(value: float) -> float:
	if value == 0.0:
		return 0.0

	var exponent := floorf(log(absf(value)) / log(10.0))
	var scale := pow(10.0, SHADER_FLOAT_SIGNIFICANT_DIGITS - 1 - exponent)

	return round(value * scale) / scale


static func _apply_enum_hint(
	parameter: ScreenEffectParameterDefinition,
	hint_string: String,
) -> void:
	var option_entries := hint_string.split(",")

	assert(not option_entries.is_empty(), "Enum options must not be empty: %s" % parameter.id)

	for index in option_entries.size():
		var entry := option_entries[index].strip_edges()
		var value_parts := entry.split(":", false, 1)

		parameter.options.append(value_parts[0].strip_edges())

		if value_parts.size() == 2:
			parameter.option_values.append(value_parts[1].to_int())
		else:
			parameter.option_values.append(index)
