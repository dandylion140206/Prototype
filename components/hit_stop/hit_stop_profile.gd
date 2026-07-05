class_name HitStopProfile
extends Resource

@export_range(0.0, 20000.0, 100.0) var min_speed: float = 500.0
@export_range(0.0, 20000.0, 100.0) var max_speed: float = 4000.0
@export_range(0.0, 0.5, 0.001) var min_duration: float = 0.001
@export_range(0.0, 0.5, 0.001) var max_duration: float = 0.03


func calculate_duration(speed: float) -> float:
	if speed < min_speed:
		return 0.0

	if speed >= max_speed:
		return max_duration

	var ratio := inverse_lerp(min_speed, max_speed, speed)
	return lerpf(min_duration, max_duration, ratio)
