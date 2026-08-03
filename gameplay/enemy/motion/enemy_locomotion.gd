class_name EnemyLocomotion
extends Node

## MovementBehaviorの希望速度を通常移動速度へ変換するコンポーネント。

var _stats: EnemyStats
var _movement_behavior: EnemyMovementBehavior
var _motion_modifiers: EnemyMotionModifierStack
var _velocity := Vector2.ZERO


func setup(
	stats: EnemyStats,
	movement_behavior: EnemyMovementBehavior,
	motion_modifiers: EnemyMotionModifierStack
) -> void:
	assert(stats != null, "stats must not be null.")
	assert(movement_behavior != null, "movement_behavior must not be null.")
	assert(motion_modifiers != null, "motion_modifiers must not be null.")

	stats.validate()
	_stats = stats
	_movement_behavior = movement_behavior
	_motion_modifiers = motion_modifiers


func set_movement_behavior(behavior: EnemyMovementBehavior) -> void:
	assert(behavior != null, "behavior must not be null.")
	_movement_behavior = behavior


func update(origin: Vector2, delta: float) -> Vector2:
	assert(_stats != null, "EnemyLocomotion must be setup before use.")
	assert(_movement_behavior != null, "movement_behavior must not be null.")
	assert(_motion_modifiers != null, "motion_modifiers must not be null.")

	var speed_multiplier := _motion_modifiers.get_speed_multiplier()
	var target_speed := _stats.target_speed * speed_multiplier
	var max_speed := _stats.max_speed * speed_multiplier

	var desired_velocity := _movement_behavior.get_desired_velocity(
		origin,
		target_speed,
		delta
	)

	desired_velocity = desired_velocity.limit_length(max_speed)
	_velocity = _velocity.move_toward(
		desired_velocity,
		_stats.acceleration * delta
	)
	_velocity = _velocity.limit_length(max_speed)
	return _velocity


func get_velocity() -> Vector2:
	return _velocity
