class_name EnemyFollowTargetBehavior
extends EnemyMovementBehavior

@export var target: Node2D
@export_range(0.0, 1000.0, 1.0, "or_greater") var arrival_distance: float = 0.0


func _ready() -> void:
	_validate()


func configure(p_target: Node2D, p_arrival_distance: float) -> void:
	assert(p_target != null, "target must not be null.")
	target = p_target
	arrival_distance = p_arrival_distance
	_validate()


func get_desired_velocity(
	current_position: Vector2,
	effective_target_speed: float,
	_delta: float
) -> Vector2:
	if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
		target = null
		return Vector2.ZERO

	var to_target := target.global_position - current_position
	if to_target.length_squared() <= arrival_distance * arrival_distance:
		return Vector2.ZERO

	return to_target.normalized() * effective_target_speed


func _validate() -> void:
	assert(target != null, "target must not be null.")
	assert(arrival_distance >= 0.0, "arrival_distance must not be negative.")
