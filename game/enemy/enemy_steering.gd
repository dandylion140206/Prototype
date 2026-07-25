class_name EnemySteering
extends Node

@export_range(0.0, 10000.0, 1.0) var target_speed: float = 100.0
@export_range(0.0, 1000.0, 0.1) var arrival_distance: float = 2.0
@export_range(0.0, 10.0, 0.01) var seek_weight: float = 1.0
@export_range(0.0, 10.0, 0.01) var wander_weight: float = 0.2
@export_range(0.0, 90.0, 0.1, "degrees") var wander_strength: float = 20.0
@export_range(0.0, 20.0, 0.1) var wander_speed: float = 2.0

var _wander_time: float = 0.0
var _wander_phase: float = 0.0


func _ready() -> void:
	_wander_phase = randf_range(0.0, TAU)


func get_desired_velocity(
	position: Vector2,
	current_velocity: Vector2,
	destination: Vector2,
	delta: float
) -> Vector2:
	var to_destination := destination - position
	if to_destination.length() <= arrival_distance:
		return Vector2.ZERO

	var seek_direction := to_destination.normalized()
	var steering := seek_direction * seek_weight
	steering += _get_wander_force(seek_direction, current_velocity, delta) * wander_weight
	return steering.limit_length(1.0) * target_speed


func _get_wander_force(
	seek_direction: Vector2,
	current_velocity: Vector2,
	delta: float
) -> Vector2:
	_wander_time += delta

	var base_direction := seek_direction
	if base_direction.is_zero_approx() and not current_velocity.is_zero_approx():
		base_direction = current_velocity.normalized()

	var wander_angle := sin(_wander_time * wander_speed + _wander_phase) * deg_to_rad(wander_strength)

	return base_direction.rotated(wander_angle)
