class_name Movement
extends Node

@export_range(100.0, 10000.0, 100.0) var target_speed: float = 6000.0
@export_range(100.0, 20000.0, 100.0) var acceleration: float = 10000.0
@export_range(100.0, 20000.0, 100.0) var max_speed: float = 7000.0

var _body: Node2D
var _velocity := Vector2.ZERO


func setup(body: Node2D) -> void:
	assert(body != null, "body must not be null.")

	_body = body


func update_velocity(
	current_position: Vector2,
	target_position: Vector2,
	delta: float
) -> void:
	var to_target := target_position - current_position

	if to_target.is_zero_approx():
		_velocity = _velocity.move_toward(
			Vector2.ZERO,
			acceleration * delta
		)
		return

	var target_velocity := to_target.normalized() * target_speed
	var new_velocity := _velocity.move_toward(
		target_velocity,
		acceleration * delta
	)

	set_velocity(new_velocity)


func get_velocity() -> Vector2:
	return _velocity


func get_speed() -> float:
	return _velocity.length()


func set_velocity(velocity: Vector2) -> void:
	_velocity = velocity.limit_length(max_speed)


func add_velocity(delta_velocity: Vector2) -> void:
	set_velocity(_velocity + delta_velocity)


func move(delta: float) -> void:
	assert(_body != null, "Movement must be setup before move().")

	_body.global_position += _velocity * delta
