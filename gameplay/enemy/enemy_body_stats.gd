class_name EnemyBodyStats
extends Resource

## 敵の物理特性と群衆挙動のチューニング値。
## 実行時に書き換える用途は想定していないため、複数の敵で共有してよい。

@export_range(0.1, 30.0, 0.1, "or_greater") var mass: float = 1.0
@export var is_immovable: bool = false

@export_group("Separation")
@export_range(0.0, 10000.0, 1.0) var separation_weight: float = 600.0
@export_range(0.0, 1000.0, 1.0) var separation_radius: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_separation_acceleration: float = 900.0

@export_group("Crowd Damping")
@export_range(0.0, 100.0, 0.1) var crowd_damping: float = 12.0
@export_range(0.0, 10000.0, 1.0) var max_crowd_damping_acceleration: float = 1200.0

@export_group("Overlap")
@export_range(0.0, 100.0, 1.0) var overlap_radius: float = 24.0
@export_range(1, 8, 1) var overlap_iterations: int = 3


func get_inverse_mass() -> float:
	if is_immovable:
		return 0.0

	return 1.0 / maxf(mass, 0.0001)
