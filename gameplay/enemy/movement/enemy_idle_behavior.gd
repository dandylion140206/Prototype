class_name EnemyIdleBehavior
extends EnemyMovementBehavior


func get_desired_velocity(
	_current_position: Vector2,
	_effective_target_speed: float,
	_delta: float
) -> Vector2:
	return Vector2.ZERO
