class_name EnemyMoveToPositionBehavior
extends EnemyMovementBehavior

@export var destination: Vector2 = Vector2.ZERO
@export_range(0.0, 1000.0, 1.0, "or_greater") var arrival_distance: float = 0.0


func configure(p_destination: Vector2, p_arrival_distance: float) -> void:
	destination = p_destination
	arrival_distance = p_arrival_distance
	_validate()


func get_desired_velocity(
	current_position: Vector2,
	effective_target_speed: float,
	_delta: float
) -> Vector2:
	var to_destination := destination - current_position
	if to_destination.length_squared() <= arrival_distance * arrival_distance:
		return Vector2.ZERO

	return to_destination.normalized() * effective_target_speed


func _validate() -> void:
	assert(arrival_distance >= 0.0, "arrival_distance must not be negative.")
