class_name EnemyCrowdAgent
extends Node

## EnemyCrowdSystemとEnemyMotorの間の窓口。
## Crowd側はEnemy本体を参照せず、このAgentだけを扱う。

@export var crowd_stats: EnemyCrowdStats

var _motor: EnemyMotor
var _motion_modifiers: EnemyMotionModifierStack
var _hit_stop: HitStop


func setup(
	motor: EnemyMotor,
	motion_modifiers: EnemyMotionModifierStack,
	hit_stop: HitStop
) -> void:
	assert(crowd_stats != null, "crowd_stats must not be null.")
	assert(motor != null, "motor must not be null.")
	assert(motion_modifiers != null, "motion_modifiers must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")

	crowd_stats.validate()
	_motor = motor
	_motion_modifiers = motion_modifiers
	_hit_stop = hit_stop


func get_current_position() -> Vector2:
	return _motor.get_current_position()


func get_predicted_position() -> Vector2:
	return _motor.get_predicted_position()


func get_crowd_velocity() -> Vector2:
	return _motor.get_base_effective_velocity()


func get_inverse_mass() -> float:
	if is_hit_stop_active():
		return 0.0

	return _motion_modifiers.get_effective_inverse_mass()


func is_hit_stop_active() -> bool:
	return _hit_stop.is_active()


func apply_crowd_acceleration(acceleration: Vector2) -> void:
	_motor.set_crowd_acceleration(acceleration)


func set_contact_velocity_correction(correction: Vector2) -> void:
	_motor.set_contact_velocity_correction(correction)


func set_resolved_position(position: Vector2) -> void:
	_motor.set_resolved_position(position)


func get_overlap_iterations() -> int:
	return crowd_stats.overlap_iterations
