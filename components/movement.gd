class_name Movement
extends Node

@export_range(1000.0, 20000.0, 100.0) var max_speed: float = 7000.0

var _body: Node2D
var _velocity: Vector2 = Vector2.ZERO


func setup(body: Node2D) -> void:
	assert(body != null, "body must not be null.")
	_body = body


func get_velocity() -> Vector2:
	return _velocity


func set_velocity(velocity: Vector2) -> void:
	_velocity = velocity.limit_length(max_speed)


func add_velocity(delta_velocity: Vector2) -> void:
	set_velocity(_velocity + delta_velocity)


func move(delta: float) -> void:
	if _body == null:
		return

	_body.global_position += _velocity * delta
