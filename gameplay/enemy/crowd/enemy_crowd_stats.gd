class_name EnemyCrowdStats
extends Resource

## Crowd処理だけで使用する静的な設定。

@export_group("Separation")
@export_range(0.0, 1000.0, 1.0, "or_greater") var separation_radius: float = 50.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var separation_speed: float = 80.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var max_crowd_speed: float = 120.0
@export_range(0.0, 1.0, 0.01) var approach_damping: float = 1.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var max_approach_damping_speed: float = 100.0

@export_group("Overlap")
@export_range(0.0, 1000.0, 1.0, "or_greater") var overlap_radius: float = 24.0
@export_range(1, 32, 1, "or_greater") var overlap_iterations: int = 3


func validate() -> void:
	assert(separation_radius >= 0.0, "separation_radius must not be negative.")
	assert(separation_speed >= 0.0, "separation_speed must not be negative.")
	assert(max_crowd_speed >= 0.0, "max_crowd_speed must not be negative.")
	assert(
		approach_damping >= 0.0 and approach_damping <= 1.0,
		"approach_damping must be between zero and one."
	)
	assert(
		max_approach_damping_speed >= 0.0,
		"max_approach_damping_speed must not be negative."
	)
	assert(overlap_radius >= 0.0, "overlap_radius must not be negative.")
	assert(
		overlap_radius <= separation_radius,
		"overlap_radius must not exceed separation_radius."
	)
	assert(overlap_iterations >= 1, "overlap_iterations must be at least one.")
