class_name ShaderParameterDefinitionFactory
extends RefCounted


static func create_all(shader: Shader) -> Array[EffectParameterDefinition]:
	assert(shader != null, "Shader must not be null")

	var material := ShaderMaterial.new()
	material.shader = shader

	var parameters: Array[EffectParameterDefinition] = []

	for uniform_data in shader.get_shader_uniform_list():
		var parameter := _create_parameter(
			uniform_data,
			material,
		)

		if parameter != null:
			parameters.append(parameter)

	return parameters


static func _create_parameter(
	uniform_data: Dictionary,
	material: ShaderMaterial,
) -> EffectParameterDefinition:
	if not uniform_data.has("name") or not uniform_data.has("type"):
		return null

	var parameter_id := StringName(uniform_data["name"])
	var type: int = uniform_data["type"]
	var hint: int = uniform_data.get("hint", PROPERTY_HINT_NONE)
	var hint_string := String(
		uniform_data.get("hint_string", "")
	)

	var parameter := EffectParameterDefinition.new()
	parameter.id = parameter_id
	parameter.display_name = String(parameter_id).capitalize()
	parameter.default_value = material.get_shader_parameter(
		parameter_id
	)

	match type:
		TYPE_BOOL:
			parameter.kind = EffectParameterDefinition.Kind.BOOLEAN

		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				parameter.kind = EffectParameterDefinition.Kind.ENUM
				_apply_enum_hint(parameter, hint_string)
			else:
				parameter.kind = EffectParameterDefinition.Kind.INTEGER
				_apply_range_hint(parameter, hint, hint_string)

		TYPE_FLOAT:
			parameter.kind = EffectParameterDefinition.Kind.FLOAT
			_apply_range_hint(parameter, hint, hint_string)

		TYPE_OBJECT:
			return null

		_:
			push_warning(
				"Unsupported shader parameter type '%s': %s"
				% [type, parameter_id]
			)
			return null

	parameter.default_value = parameter.normalize_value(
		parameter.default_value
	)

	return parameter


static func _apply_range_hint(
	parameter: EffectParameterDefinition,
	hint: int,
	hint_string: String,
) -> void:
	assert(
		hint == PROPERTY_HINT_RANGE,
		"Numeric shader parameter requires hint_range: %s"
		% parameter.id,
	)

	var range_parts := hint_string.split(",")
	assert(
		range_parts.size() >= 2,
		"Invalid hint_range: %s" % parameter.id,
	)

	parameter.min_value = range_parts[0].to_float()
	parameter.max_value = range_parts[1].to_float()

	if range_parts.size() >= 3:
		parameter.step = range_parts[2].to_float()
	else:
		parameter.step = (
			1.0
			if parameter.kind == EffectParameterDefinition.Kind.INTEGER
			else 0.01
		)

	assert(
		parameter.min_value <= parameter.max_value,
		"Invalid parameter range: %s" % parameter.id,
	)
	assert(
		parameter.step > 0.0,
		"Parameter step must be greater than zero: %s"
		% parameter.id,
	)


static func _apply_enum_hint(
	parameter: EffectParameterDefinition,
	hint_string: String,
) -> void:
	var option_entries := hint_string.split(",")
	assert(
		not option_entries.is_empty(),
		"Enum options must not be empty: %s" % parameter.id,
	)

	for index in option_entries.size():
		var entry := option_entries[index].strip_edges()
		var value_parts := entry.split(":", false, 1)

		parameter.options.append(value_parts[0].strip_edges())

		if value_parts.size() == 2:
			parameter.option_values.append(
				value_parts[1].to_int()
			)
		else:
			parameter.option_values.append(index)

	assert(
		parameter.option_values.has(
			int(parameter.default_value)
		),
		"Enum default value is not included in options: %s"
		% parameter.id,
	)
