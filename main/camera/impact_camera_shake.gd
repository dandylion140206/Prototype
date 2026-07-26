class_name ImpactCameraShake
extends Node

@export_range(0.0, 20000.0, 100.0) var min_shake_speed: float = 1000.0
@export_range(0.0, 20000.0, 100.0) var max_shake_speed: float = 7000.0
@export_range(0.0, 1.0, 0.01) var trauma_at_max_speed: float = 0.5

var _camera_shake: CameraShake


func setup(camera_shake: CameraShake) -> void:
	assert(camera_shake != null, "camera_shake must not be null.")
	assert(min_shake_speed < max_shake_speed, "min_shake_speed must be less than max_shake_speed.")

	_camera_shake = camera_shake


func apply_hit(hit_data: HitData) -> void:
	assert(_camera_shake != null, "ImpactCameraShake must be setup before apply_hit().")
	assert(hit_data != null, "hit_data must not be null.")

	var impact_speed := hit_data.impact_velocity.length()
	if impact_speed < min_shake_speed:
		return

	var speed_ratio := inverse_lerp(
		min_shake_speed,
		max_shake_speed,
		impact_speed
	)
	speed_ratio = clampf(speed_ratio, 0.0, 1.0)

	_camera_shake.add_trauma(
		trauma_at_max_speed * speed_ratio
	)
