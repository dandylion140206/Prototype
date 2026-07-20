class_name EffectParameterEnableRule
extends Resource

@export var condition_parameter: StringName
@export var enabled_values: Array[Variant] = []
@export var target_parameters: Array[StringName] = []


func validate(parameter_ids: Dictionary[StringName, bool]) -> void:
	assert(
		parameter_ids.has(condition_parameter),
		"Unknown condition parameter: %s" % condition_parameter,
	)
	assert(
		not enabled_values.is_empty(),
		"Enabled values must not be empty: %s" % condition_parameter,
	)
	assert(
		not target_parameters.is_empty(),
		"Target parameters must not be empty: %s" % condition_parameter,
	)

	for parameter_id in target_parameters:
		assert(
			parameter_ids.has(parameter_id),
			"Unknown target parameter: %s" % parameter_id,
		)
		assert(
			parameter_id != condition_parameter,
			"Parameter cannot control itself: %s" % parameter_id,
		)


func is_enabled(condition_value: Variant) -> bool:
	return enabled_values.has(condition_value)
