class_name Ball
extends Node2D

@export var seek_steering: SeekSteering

var _velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not _validate_setup():
		set_process(false)
		return


func _process(delta: float) -> void:
	var target_position := get_global_mouse_position()

	_update_velocity(target_position, delta)
	global_position += _velocity * delta


func _update_velocity(target_position: Vector2, delta: float) -> void:
	_velocity = seek_steering.calculate_velocity(
		_velocity,
		global_position,
		target_position,
		delta
	)


func _validate_setup() -> bool:
	var is_valid := true

	if seek_steering == null:
		push_error("seek_steering is not assigned.")
		is_valid = false

	return is_valid
