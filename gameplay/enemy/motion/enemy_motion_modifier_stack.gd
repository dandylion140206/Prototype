class_name EnemyMotionModifierStack
extends Node

var _base_mass: float = 1.0
var _modifiers: Dictionary[int, EnemyMotionModifier] = {}
var _next_modifier_id: int = 1


func setup(base_mass: float) -> void:
	assert(base_mass > 0.0, "base_mass must be greater than zero.")
	_base_mass = base_mass


func add_modifier(modifier: EnemyMotionModifier) -> int:
	assert(modifier != null, "modifier must not be null.")
	modifier.validate()

	var modifier_id := _next_modifier_id
	_next_modifier_id += 1
	_modifiers[modifier_id] = modifier
	return modifier_id


func remove_modifier(modifier_id: int) -> void:
	_modifiers.erase(modifier_id)


func get_speed_multiplier() -> float:
	var multiplier := 1.0
	for modifier: EnemyMotionModifier in _modifiers.values():
		multiplier *= modifier.speed_multiplier

	return multiplier


func get_mass_multiplier() -> float:
	var multiplier := 1.0
	for modifier: EnemyMotionModifier in _modifiers.values():
		multiplier *= modifier.mass_multiplier

	return multiplier


func get_effective_mass() -> float:
	return _base_mass * get_mass_multiplier()


func get_effective_inverse_mass() -> float:
	return 1.0 / get_effective_mass()
