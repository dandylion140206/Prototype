class_name CameraTargetFollow
extends Node

@export_range(0.0, 1.0, 0.01) var horizontal_follow_ratio: float = 0.1
@export_range(0.0, 1.0, 0.01) var vertical_follow_ratio: float = 0.08
@export var dead_zone_half_size: Vector2 = Vector2(160.0, 90.0)
@export var max_displacement: Vector2 = Vector2(96.0, 54.0)
@export_range(0.1, 20.0, 0.1) var smoothing_speed: float = 4.0

var _camera: Camera2D
var _target_position_provider: Callable
var _base_camera_position: Vector2 = Vector2.ZERO
var _base_view_center: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if _camera == null:
		return

	var target_position: Vector2 = _target_position_provider.call()
	var target_displacement := target_position - _base_view_center
	var desired_displacement := Vector2(
		_get_axis_displacement(
			target_displacement.x,
			dead_zone_half_size.x,
			horizontal_follow_ratio,
			max_displacement.x
		),
		_get_axis_displacement(
			target_displacement.y,
			dead_zone_half_size.y,
			vertical_follow_ratio,
			max_displacement.y
		)
	)
	var desired_position := _base_camera_position + desired_displacement
	var smoothing_weight := 1.0 - exp(-smoothing_speed * delta)

	_camera.global_position = _camera.global_position.lerp(desired_position, smoothing_weight)


func _exit_tree() -> void:
	if not is_instance_valid(_camera):
		return

	_camera.global_position = _base_camera_position


func setup(camera: Camera2D, target_position_provider: Callable) -> void:
	assert(camera != null, "camera must not be null.")
	assert(target_position_provider.is_valid(), "target_position_provider must be valid.")
	assert(dead_zone_half_size.x >= 0.0 and dead_zone_half_size.y >= 0.0, "dead_zone_half_size must not be negative.")
	assert(max_displacement.x >= 0.0 and max_displacement.y >= 0.0, "max_displacement must not be negative.")

	_camera = camera
	_target_position_provider = target_position_provider
	_base_camera_position = _camera.global_position
	_base_view_center = _base_camera_position + _camera.offset


func reset() -> void:
	assert(_camera != null, "CameraTargetFollow must be setup before reset().")

	_camera.global_position = _base_camera_position


func _get_axis_displacement(
	target_displacement: float,
	dead_zone: float,
	follow_ratio: float,
	maximum_displacement: float
) -> float:
	var distance_outside_dead_zone := maxf(absf(target_displacement) - dead_zone, 0.0)
	var scaled_displacement := distance_outside_dead_zone * follow_ratio

	return signf(target_displacement) * minf(scaled_displacement, maximum_displacement)
