class_name DestinationSeeker
extends Node

## 与えられた目的地へ向かう速度を計算する。エリアや追従対象は関知しない。

signal destination_reached

@export_range(0.0, 2000.0, 10.0) var acceleration: float = 300.0
@export_range(1.0, 64.0, 1.0) var arrival_distance: float = 6.0

var max_speed: float = 60.0
var velocity: Vector2 = Vector2.ZERO

var _destination: Vector2 = Vector2.ZERO
var _is_seeking: bool = false


func set_destination(destination: Vector2) -> void:
	_destination = destination
	_is_seeking = true


func stop() -> void:
	_is_seeking = false


## 速度を更新して返す。所有者が毎 physics フレーム呼び出す。
func update(origin: Vector2, delta: float) -> Vector2:
	var desired_velocity := Vector2.ZERO

	if _is_seeking:
		var to_destination := _destination - origin
		if to_destination.length() <= arrival_distance:
			_is_seeking = false
			destination_reached.emit()
		else:
			desired_velocity = to_destination.normalized() * max_speed

	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	return velocity
