class_name EnemyCrowdStats
extends Resource

## Crowd処理だけで使用する静的な設定。

@export_group("Separation")
@export_range(0.0, 1000.0, 1.0, "or_greater") var separation_radius: float = 50.0
@export_range(0.0, 10000.0, 1.0, "or_greater") var separation_strength: float = 600.0
@export_range(0.0, 10000.0, 1.0, "or_greater") var max_separation_acceleration: float = 900.0
@export_range(0.0, 100.0, 0.1, "or_greater") var approach_damping: float = 12.0
@export_range(0.0, 10000.0, 1.0, "or_greater") var max_approach_damping_acceleration: float = 1200.0

@export_group("Overlap")
@export_range(0.0, 1000.0, 1.0, "or_greater") var overlap_radius: float = 24.0
@export_range(1, 32, 1, "or_greater") var overlap_iterations: int = 3


func validate() -> void:
	assert(separation_radius >= 0.0, "separation_radius must not be negative.")
	assert(separation_strength >= 0.0, "separation_strength must not be negative.")
	assert(
		max_separation_acceleration >= 0.0,
		"max_separation_acceleration must not be negative."
	)
	assert(approach_damping >= 0.0, "approach_damping must not be negative.")
	assert(
		max_approach_damping_acceleration >= 0.0,
		"max_approach_damping_acceleration must not be negative."
	)
	assert(overlap_radius >= 0.0, "overlap_radius must not be negative.")
	assert(overlap_iterations >= 1, "overlap_iterations must be at least one.")
