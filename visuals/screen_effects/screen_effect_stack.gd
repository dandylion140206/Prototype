class_name ScreenEffectStack
extends CanvasLayer


func _ready() -> void:
	for effect_pass in _get_effect_passes():
		assert(effect_pass.state != null, "Screen effect state must be initialized: %s" % effect_pass.name)


func get_states() -> Array[ScreenEffectState]:
	var states: Array[ScreenEffectState] = []

	for effect_pass in _get_effect_passes():
		assert(effect_pass.state != null, "Screen effect state must be initialized: %s" % effect_pass.name)
		states.append(effect_pass.state)

	return states


func _get_effect_passes() -> Array[ScreenEffectPass]:
	var effect_passes: Array[ScreenEffectPass] = []

	for child in get_children():
		assert(child is ScreenEffectPass, "ScreenEffectStack children must be ScreenEffectPass nodes")
		effect_passes.append(child as ScreenEffectPass)

	return effect_passes
