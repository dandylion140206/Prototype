class_name EnemyDestination
extends Node

var _fixed_destination: Vector2 = Vector2.ZERO
var _has_fixed_destination: bool = false
var _destination_target: Node2D
var _last_destination_target_position: Vector2 = Vector2.ZERO
var _has_last_destination_target_position: bool = false


func set_destination(destination: Vector2) -> void:
	_fixed_destination = destination
	_has_fixed_destination = true


func set_destination_target(destination_target: Node2D) -> void:
	assert(destination_target != null, "destination_target must not be null.")

	_destination_target = destination_target
	_last_destination_target_position = destination_target.global_position
	_has_last_destination_target_position = true


func clear_destination_target() -> void:
	_destination_target = null


func clear_destination() -> void:
	_destination_target = null
	_has_fixed_destination = false
	_has_last_destination_target_position = false


func get_destination() -> Variant:
	if _destination_target != null:
		if is_instance_valid(_destination_target):
			_last_destination_target_position = _destination_target.global_position
			_has_last_destination_target_position = true
			return _last_destination_target_position

		if _has_last_destination_target_position:
			_fixed_destination = _last_destination_target_position
			_has_fixed_destination = true

		_destination_target = null

	if _has_fixed_destination:
		return _fixed_destination

	return null


func has_destination() -> bool:
	return get_destination() != null
