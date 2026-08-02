class_name AbilityController
extends Node

signal audio_requested(request: AudioRequest)

@export var primary_ability: AbilityDefinition
@export var secondary_ability: AbilityDefinition

var _context: AbilityContext
var _primary_ability: Ability
var _secondary_ability: Ability


func setup(context: AbilityContext) -> void:
	assert(context != null, "context must not be null.")

	_context = context

	if primary_ability != null:
		_primary_ability = _equip_ability(primary_ability)

	if secondary_ability != null:
		_secondary_ability = _equip_ability(secondary_ability)


func try_activate_primary() -> bool:
	return _try_activate(_primary_ability)


func try_activate_secondary() -> bool:
	return _try_activate(_secondary_ability)


func get_secondary_ability() -> Ability:
	return _secondary_ability


func _try_activate(ability: Ability) -> bool:
	assert(_context != null, "AbilityController must be setup before activating an ability.")

	if ability == null:
		return false

	return ability.try_activate()


func _exit_tree() -> void:
	_teardown_ability(_primary_ability)
	_teardown_ability(_secondary_ability)
	_primary_ability = null
	_secondary_ability = null
	_context = null


func _equip_ability(definition: AbilityDefinition) -> Ability:
	assert(_context != null, "AbilityController must be setup before equipping an ability.")

	if definition.id.is_empty():
		push_error("AbilityDefinition.id must not be empty.")
		return null

	if definition.ability_scene == null:
		push_error("AbilityDefinition.ability_scene must not be null.")
		return null

	var instance := definition.ability_scene.instantiate()

	if not instance is Ability:
		push_error("The root node of ability_scene must inherit Ability.")
		instance.free()
		return null

	var ability := instance as Ability
	add_child(ability)
	ability.audio_requested.connect(_on_ability_audio_requested)
	ability.setup(_context)
	return ability


func _teardown_ability(ability: Ability) -> void:
	if ability == null:
		return

	if ability.audio_requested.is_connected(_on_ability_audio_requested):
		ability.audio_requested.disconnect(_on_ability_audio_requested)

	ability.teardown()
	ability.queue_free()


func _on_ability_audio_requested(audio_request: AudioRequest) -> void:
	audio_requested.emit(audio_request)
