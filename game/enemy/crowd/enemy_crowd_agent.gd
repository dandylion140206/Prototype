class_name EnemyCrowdAgent
extends Node

## EnemyCrowdSystem が敵個体を操作するための窓口。
## Solver は Enemy 型を知らず、このクラス経由でのみ個体へアクセスする。

var stats: EnemyBodyStats

var _body: Node2D
var _movement: EnemyMovement
var _knockback: EnemyKnockback
var _is_active: bool = true


func setup(
	body: Node2D,
	body_stats: EnemyBodyStats,
	movement: EnemyMovement,
	knockback: EnemyKnockback
) -> void:
	assert(body_stats != null, "body_stats must not be null.")

	_body = body
	stats = body_stats
	_movement = movement
	_knockback = knockback


func is_active() -> bool:
	return _is_active


func set_active(active: bool) -> void:
	_is_active = active


func get_position() -> Vector2:
	return _body.global_position


func set_position(position: Vector2) -> void:
	_body.global_position = position


func get_effective_velocity() -> Vector2:
	return _movement.get_effective_velocity() + _knockback.get_velocity()


func apply_crowd_acceleration(acceleration: Vector2) -> void:
	_movement.apply_crowd_acceleration(acceleration)
