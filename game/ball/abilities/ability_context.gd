class_name AbilityContext
extends RefCounted

var body: Node2D
var movement: BallMovement
var hit_stop: HitStop
var position_interpolator: PhysicsPositionInterpolator


func _init(
	p_body: Node2D,
	p_movement: BallMovement,
	p_hit_stop: HitStop,
	p_position_interpolator: PhysicsPositionInterpolator
) -> void:
	assert(p_body != null, "p_body must not be null.")
	assert(p_movement != null, "p_movement must not be null.")
	assert(p_hit_stop != null, "p_hit_stop must not be null.")
	assert(p_position_interpolator != null, "p_position_interpolator must not be null.")

	body = p_body
	movement = p_movement
	hit_stop = p_hit_stop
	position_interpolator = p_position_interpolator
