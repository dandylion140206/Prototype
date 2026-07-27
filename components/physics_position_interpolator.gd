class_name PhysicsPositionInterpolator
extends Node

var _source: Node2D
var _previous_physics_position: Vector2 = Vector2.ZERO
var _current_physics_position: Vector2 = Vector2.ZERO


func setup(source: Node2D) -> void:
	assert(source != null, "source must not be null.")

	_source = source
	reset()


func record_position() -> void:
	assert(_source != null, "PhysicsPositionInterpolator must be setup before record_position().")

	_previous_physics_position = _current_physics_position
	_current_physics_position = _source.global_position


func reset() -> void:
	assert(_source != null, "PhysicsPositionInterpolator must be setup before reset().")

	_previous_physics_position = _source.global_position
	_current_physics_position = _source.global_position
	_source.reset_physics_interpolation()


func get_interpolated_global_position() -> Vector2:
	assert(_source != null, "PhysicsPositionInterpolator must be setup before getting a position.")

	var interpolation_fraction := Engine.get_physics_interpolation_fraction()

	return _previous_physics_position.lerp(_current_physics_position, interpolation_fraction)
