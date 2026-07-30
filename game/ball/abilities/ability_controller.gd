class_name AbilityController
extends Node

signal audio_requested(request: AudioRequest)

@export var initial_ability: AbilityDefinition

var _context: AbilityContext
var _ability: Ability


func setup(context: AbilityContext) -> void:
	assert(context != null, "context must not be null.")

	_context = context

	if initial_ability != null:
		_equip_ability(initial_ability)


func try_activate() -> bool:
	assert(_context != null, "AbilityController must be setup before try_activate().")

	if _ability == null:
		return false

	return _ability.try_activate()


func _exit_tree() -> void:
	_teardown_ability()
	_context = null


func _equip_ability(definition: AbilityDefinition) -> bool:
	assert(_context != null, "AbilityController must be setup before equipping an ability.")

	if definition.id.is_empty():
		push_error("AbilityDefinition.id must not be empty.")
		return false

	if definition.ability_scene == null:
		push_error("AbilityDefinition.ability_scene must not be null.")
		return false

	var instance := definition.ability_scene.instantiate()

	if not instance is Ability:
		push_error("The root node of ability_scene must inherit Ability.")
		instance.free()
		return false

	_teardown_ability()

	_ability = instance as Ability
	add_child(_ability)
	_ability.audio_requested.connect(_on_ability_audio_requested)
	_ability.setup(_context)
	return true


func _teardown_ability() -> void:
	if _ability == null:
		return

	if _ability.audio_requested.is_connected(_on_ability_audio_requested):
		_ability.audio_requested.disconnect(_on_ability_audio_requested)

	_ability.teardown()
	_ability.queue_free()
	_ability = null


func _on_ability_audio_requested(audio_request: AudioRequest) -> void:
	audio_requested.emit(audio_request)
