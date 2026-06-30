class_name SeekSteering
extends Resource

@export_range(1000.0, 10000.0, 100.0) var target_speed: float = 5500.0
@export_range(1000.0, 20000.0, 100.0) var acceleration: float = 11000.0
@export_range(1000.0, 20000.0, 100.0) var max_speed: float = 7000.0

func calculate_velocity(
	current_velocity: Vector2,
	current_position: Vector2,
	target_position: Vector2,
	delta: float
) -> Vector2:
	var to_target := target_position - current_position

	if to_target.is_zero_approx():
		return current_velocity.move_toward(Vector2.ZERO, acceleration * delta)


	var target_velocity := to_target.normalized() * target_speed

	var new_velocity := current_velocity.move_toward(
		target_velocity,
		acceleration * delta
	)

	return new_velocity.limit_length(max_speed)
