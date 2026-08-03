class_name EnemyMotor
extends Node

enum VelocitySource {
	LOCOMOTION,
	KNOCKBACK,
	CROWD,
	COUNT,
}

var _body: Node2D
var _locomotion: EnemyLocomotion
var _knockback: EnemyKnockback
var _hit_stop: HitStop

var _velocity_sources := PackedVector2Array()
var _requested_velocity := Vector2.ZERO
var _actual_velocity := Vector2.ZERO

var _frame_start_position := Vector2.ZERO
var _predicted_position := Vector2.ZERO
var _resolved_position := Vector2.ZERO

var _is_motion_paused: bool = false


func setup(
	body: Node2D,
	locomotion: EnemyLocomotion,
	knockback: EnemyKnockback,
	hit_stop: HitStop
) -> void:
	assert(body != null, "body must not be null.")
	assert(locomotion != null, "locomotion must not be null.")
	assert(knockback != null, "knockback must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")

	_body = body
	_locomotion = locomotion
	_knockback = knockback
	_hit_stop = hit_stop

	_velocity_sources.resize(VelocitySource.COUNT)
	_clear_velocity_sources()

	_frame_start_position = _body.global_position
	_predicted_position = _frame_start_position
	_resolved_position = _frame_start_position
	_requested_velocity = Vector2.ZERO
	_actual_velocity = Vector2.ZERO


func begin_frame() -> void:
	_frame_start_position = _body.global_position
	_predicted_position = _frame_start_position
	_resolved_position = _frame_start_position

	_requested_velocity = Vector2.ZERO
	_clear_velocity_sources()

	_is_motion_paused = _hit_stop.is_active()
	if _is_motion_paused:
		_actual_velocity = Vector2.ZERO


func update_sources(delta: float) -> void:
	if _is_motion_paused:
		return

	_velocity_sources[VelocitySource.LOCOMOTION] = _locomotion.update(
		_body.global_position,
		delta
	)

	_knockback.update_decay(delta)
	_velocity_sources[VelocitySource.KNOCKBACK] = _knockback.get_velocity()


func set_crowd_velocity(velocity: Vector2) -> void:
	if _is_motion_paused:
		return

	_velocity_sources[VelocitySource.CROWD] = velocity


func prepare_prediction(delta: float) -> void:
	if _is_motion_paused:
		_requested_velocity = Vector2.ZERO
		_predicted_position = _frame_start_position
		_resolved_position = _frame_start_position
		return

	_requested_velocity = _compose_requested_velocity()
	_predicted_position = _frame_start_position + _requested_velocity * delta
	_resolved_position = _predicted_position


func set_resolved_position(position: Vector2) -> void:
	_resolved_position = position


func apply_resolved_position(delta: float) -> void:
	if _is_motion_paused:
		_actual_velocity = Vector2.ZERO
		return

	_body.global_position = _resolved_position

	if delta <= 0.0:
		_actual_velocity = Vector2.ZERO
		return

	_actual_velocity = (_resolved_position - _frame_start_position) / delta


func get_current_position() -> Vector2:
	return _body.global_position


func get_predicted_position() -> Vector2:
	return _predicted_position


func get_resolved_position() -> Vector2:
	return _resolved_position


func get_locomotion_velocity() -> Vector2:
	return _velocity_sources[VelocitySource.LOCOMOTION]


func get_knockback_velocity() -> Vector2:
	return _velocity_sources[VelocitySource.KNOCKBACK]


func get_crowd_velocity() -> Vector2:
	return _velocity_sources[VelocitySource.CROWD]


func get_base_velocity() -> Vector2:
	return get_locomotion_velocity() + get_knockback_velocity()


func get_requested_velocity() -> Vector2:
	return _requested_velocity


func get_actual_velocity() -> Vector2:
	return _actual_velocity


func is_motion_paused() -> bool:
	return _is_motion_paused


func _clear_velocity_sources() -> void:
	for index in range(VelocitySource.COUNT):
		_velocity_sources[index] = Vector2.ZERO


func _compose_requested_velocity() -> Vector2:
	var result := Vector2.ZERO

	for index in range(VelocitySource.COUNT):
		result += _velocity_sources[index]

	return result
