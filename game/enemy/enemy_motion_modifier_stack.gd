class_name EnemyMotionModifierStack
extends Node

const ENEMY_MOTION_MODIFIER_RESOURCE = preload("res://game/enemy/enemy_motion_modifier.gd")

var _modifiers: Dictionary[int, ENEMY_MOTION_MODIFIER_RESOURCE] = {}
var _next_modifier_id: int = 1


func add_modifier(modifier: ENEMY_MOTION_MODIFIER_RESOURCE) -> int:
	assert(modifier != null, "modifier must not be null.")

	var modifier_id := _next_modifier_id
	_next_modifier_id += 1
	_modifiers[modifier_id] = modifier

	return modifier_id


func remove_modifier(modifier_id: int) -> void:
	_modifiers.erase(modifier_id)


func get_speed_multiplier() -> float:
	var multiplier: float = 1.0
	for modifier: ENEMY_MOTION_MODIFIER_RESOURCE in _modifiers.values():
		multiplier *= modifier.speed_multiplier

	return multiplier


func get_mass_multiplier() -> float:
	var multiplier: float = 1.0
	for modifier: ENEMY_MOTION_MODIFIER_RESOURCE in _modifiers.values():
		multiplier *= modifier.mass_multiplier

	return multiplier
