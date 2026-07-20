class_name ScreenEffects
extends Node

@export var base_layer := 100
@export var effects: Array[ScreenEffect] = []


func _ready() -> void:
	for index in effects.size():
		var effect := effects[index]

		assert(effect != null, "Screen effect must not be null at index %s" % index)
		assert(effect.model != null, "Screen effect model must be initialized: %s" % effect.name)

		effect.layer = base_layer + index


func get_models() -> Array[EffectModel]:
	var models: Array[EffectModel] = []

	for effect in effects:
		assert(effect != null, "Screen effect must not be null")
		assert(effect.model != null, "Screen effect model must be initialized")
		models.append(effect.model)

	return models
