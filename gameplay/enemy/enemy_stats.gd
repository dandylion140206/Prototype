class_name EnemyStats
extends Resource

## Enemyの通常移動と質量に関する静的な設定。

@export_group("Movement")
@export_range(0.0, 10000.0, 1.0, "or_greater") var target_speed: float = 100.0
@export_range(0.0, 10000.0, 1.0, "or_greater") var acceleration: float = 100.0
@export_range(0.0, 10000.0, 1.0, "or_greater") var max_speed: float = 400.0

@export_group("Mass")
@export_range(0.001, 100.0, 0.001, "or_greater") var mass: float = 1.0


func validate() -> void:
	assert(target_speed >= 0.0, "target_speed must not be negative.")
	assert(acceleration >= 0.0, "acceleration must not be negative.")
	assert(max_speed >= 0.0, "max_speed must not be negative.")
	assert(mass > 0.0, "mass must be greater than zero.")
