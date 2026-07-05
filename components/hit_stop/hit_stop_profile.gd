class_name HitStopProfile
extends Resource

@export_range(0.0, 1.0, 0.001) var base_duration: float = 0.1
@export_range(0.0, 0.1, 0.001) var duration_add_per_1000_speed: float = 0.0
@export_range(0.0, 1.0, 0.001) var min_duration: float = 0.0
@export_range(0.0, 1.0, 0.001) var max_duration: float = 0.5


func calculate_duration(speed: float) -> float:
	var duration_add_per_1_speed := duration_add_per_1000_speed / 1000
	var duration := base_duration + speed * duration_add_per_1_speed
	return clampf(duration, min_duration, max_duration)
