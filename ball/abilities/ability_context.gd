class_name AbilityContext
extends RefCounted

var body: Node2D
var movement: Movement
var cancel_hit_stop: Callable
var get_interpolated_global_position: Callable


func _init(
	p_body: Node2D,
	p_movement: Movement,
	p_cancel_hit_stop: Callable,
	p_get_interpolated_global_position: Callable
) -> void:
	assert(p_body != null, "p_body must not be null.")
	assert(p_movement != null, "p_movement must not be null.")
	assert(p_cancel_hit_stop.is_valid(), "p_cancel_hit_stop must be valid.")
	assert(p_get_interpolated_global_position.is_valid(), "p_get_interpolated_global_position must be valid.")

	body = p_body
	movement = p_movement
	cancel_hit_stop = p_cancel_hit_stop
	get_interpolated_global_position = p_get_interpolated_global_position
