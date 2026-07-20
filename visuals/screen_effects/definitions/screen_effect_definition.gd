class_name ScreenEffectDefinition
extends Resource

@export var display_name: String
@export var shader: Shader
@export var enabled_by_default := true
@export var enable_rules: Array[EffectParameterEnableRule] = []


func validate(parameter_ids: Dictionary[StringName, bool]) -> void:
	assert(not display_name.is_empty(), "Screen effect display name must not be empty")
	assert(shader != null, "Screen effect shader must not be null: %s" % display_name)

	for rule in enable_rules:
		assert(rule != null, "Enable rule must not be null: %s" % display_name)
		rule.validate(parameter_ids)
