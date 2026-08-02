@abstract
class_name EnemyMovementBehavior
extends Node

## Enemyの通常移動に必要な希望速度だけを生成する基底Node。
## 位置更新やCrowd・Knockbackへのアクセスは行わない。


func activate() -> void:
	pass


@abstract
func get_desired_velocity(
	_current_position: Vector2,
	_effective_target_speed: float,
	_delta: float
) -> Vector2
