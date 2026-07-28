class_name CameraTargetFollow
extends Node

@export var max_displacement: Vector2 = Vector2(96.0, 54.0)
@export_range(0.1, 20.0, 0.1) var smoothing_speed: float = 4.0

@export_group("Position Follow")
@export_range(0.0, 1.0, 0.01) var horizontal_follow_ratio: float = 0.1
@export_range(0.0, 1.0, 0.01) var vertical_follow_ratio: float = 0.08
@export var dead_zone_half_size: Vector2 = Vector2(160.0, 90.0)

@export_group("Directional Offset")
@export var directional_max_offset: Vector2 = Vector2(40.0, 24.0)
@export_range(100.0, 20000.0, 100.0) var directional_reference_speed: float = 7000.0

var _camera: Camera2D
var _target_position_provider: Callable
var _target_velocity_provider: Callable
var _base_camera_position: Vector2 = Vector2.ZERO
var _base_view_center: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if _camera == null:
		return

	var target_position: Vector2 = _target_position_provider.call()
	var target_velocity: Vector2 = _target_velocity_provider.call()
	var position_displacement := _get_position_displacement(target_position - _base_view_center)
	var directional_displacement := _get_directional_displacement(target_velocity)
	var desired_displacement := _limit_displacement(position_displacement + directional_displacement)
	var desired_position := _base_camera_position + desired_displacement
	var smoothing_weight := 1.0 - exp(-smoothing_speed * delta)

	_camera.global_position = _camera.global_position.lerp(desired_position, smoothing_weight)


func _exit_tree() -> void:
	if not is_instance_valid(_camera):
		return

	_camera.global_position = _base_camera_position


func setup(
	camera: Camera2D,
	target_position_provider: Callable,
	target_velocity_provider: Callable
) -> void:
	assert(camera != null, "camera must not be null.")
	assert(target_position_provider.is_valid(), "target_position_provider must be valid.")
	assert(target_velocity_provider.is_valid(), "target_velocity_provider must be valid.")
	assert(dead_zone_half_size.x >= 0.0 and dead_zone_half_size.y >= 0.0, "dead_zone_half_size must not be negative.")
	assert(max_displacement.x >= 0.0 and max_displacement.y >= 0.0, "max_displacement must not be negative.")
	assert(
		directional_max_offset.x >= 0.0 and directional_max_offset.y >= 0.0,
		"directional_max_offset must not be negative."
	)
	assert(directional_reference_speed > 0.0, "directional_reference_speed must be greater than zero.")

	_camera = camera
	_target_position_provider = target_position_provider
	_target_velocity_provider = target_velocity_provider
	_base_camera_position = _camera.global_position
	_base_view_center = _base_camera_position + _camera.offset


func reset() -> void:
	assert(_camera != null, "CameraTargetFollow must be setup before reset().")

	_camera.global_position = _base_camera_position


func _get_position_displacement(target_displacement: Vector2) -> Vector2:
	return Vector2(
		_get_axis_displacement(target_displacement.x, dead_zone_half_size.x, horizontal_follow_ratio),
		_get_axis_displacement(target_displacement.y, dead_zone_half_size.y, vertical_follow_ratio)
	)


func _get_directional_displacement(target_velocity: Vector2) -> Vector2:
	if target_velocity.is_zero_approx():
		return Vector2.ZERO

	var speed_ratio := clampf(target_velocity.length() / directional_reference_speed, 0.0, 1.0)
	var direction := target_velocity.normalized()

	return Vector2(
		direction.x * directional_max_offset.x,
		direction.y * directional_max_offset.y
	) * speed_ratio


func _limit_displacement(displacement: Vector2) -> Vector2:
	return Vector2(
		clampf(displacement.x, -max_displacement.x, max_displacement.x),
		clampf(displacement.y, -max_displacement.y, max_displacement.y)
	)


func _get_axis_displacement(target_displacement: float, dead_zone: float, follow_ratio: float) -> float:
	var distance_outside_dead_zone := maxf(absf(target_displacement) - dead_zone, 0.0)

	return signf(target_displacement) * distance_outside_dead_zone * follow_ratio
