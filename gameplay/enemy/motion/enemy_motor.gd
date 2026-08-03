class_name EnemyMotor
extends Node

var _body: Node2D
var _stats: EnemyStats
var _movement_behavior: EnemyMovementBehavior
var _knockback: EnemyKnockback
var _motion_modifiers: EnemyMotionModifierStack
var _hit_stop: HitStop

var _normal_velocity := Vector2.ZERO
var _crowd_acceleration := Vector2.ZERO
var _frame_start_position := Vector2.ZERO
var _predicted_position := Vector2.ZERO
var _resolved_position := Vector2.ZERO
var _effective_velocity := Vector2.ZERO


func setup(
	body: Node2D,
	stats: EnemyStats,
	movement_behavior: EnemyMovementBehavior,
	knockback: EnemyKnockback,
	motion_modifiers: EnemyMotionModifierStack,
	hit_stop: HitStop
) -> void:
	assert(body != null, "body must not be null.")
	assert(stats != null, "stats must not be null.")
	assert(movement_behavior != null, "movement_behavior must not be null.")
	assert(knockback != null, "knockback must not be null.")
	assert(motion_modifiers != null, "motion_modifiers must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")

	_stats = stats
	_stats.validate()
	_body = body
	_movement_behavior = movement_behavior
	_knockback = knockback
	_motion_modifiers = motion_modifiers
	_hit_stop = hit_stop
	_frame_start_position = body.global_position
	_predicted_position = body.global_position
	_resolved_position = body.global_position


func set_movement_behavior(behavior: EnemyMovementBehavior) -> void:
	assert(behavior != null, "behavior must not be null.")
	_movement_behavior = behavior


func begin_frame() -> void:
	_crowd_acceleration = Vector2.ZERO
	_frame_start_position = _body.global_position
	_effective_velocity = Vector2.ZERO
	_predicted_position = _body.global_position
	_resolved_position = _body.global_position


func update_movement(delta: float) -> void:
	if is_hit_stop_active():
		return

	var speed_multiplier := _motion_modifiers.get_speed_multiplier()
	var effective_target_speed := _stats.target_speed * speed_multiplier
	var effective_max_speed := _stats.max_speed * speed_multiplier
	var desired_velocity := _movement_behavior.get_desired_velocity(
		_body.global_position,
		effective_target_speed,
		delta
	)
	desired_velocity = desired_velocity.limit_length(effective_max_speed)
	_normal_velocity = _normal_velocity.move_toward(desired_velocity, _stats.acceleration * delta)


func update_knockback(delta: float) -> void:
	if is_hit_stop_active():
		return

	_knockback.update_decay(delta)


func apply_crowd_acceleration(delta: float) -> void:
	if is_hit_stop_active():
		_crowd_acceleration = Vector2.ZERO
		return

	_normal_velocity += _crowd_acceleration * delta
	_crowd_acceleration = Vector2.ZERO
	_normal_velocity = _normal_velocity.limit_length(_get_effective_max_speed())


func set_crowd_acceleration(acceleration: Vector2) -> void:
	_crowd_acceleration = acceleration


func apply_contact_velocity_correction(correction: Vector2) -> void:
	if correction.is_zero_approx() or is_hit_stop_active():
		return

	var correction_direction := correction.normalized()
	var normal_contribution := maxf(
		0.0,
		-_normal_velocity.dot(correction_direction)
	)
	var knockback_velocity := _knockback.get_velocity()
	var knockback_contribution := maxf(
		0.0,
		-knockback_velocity.dot(correction_direction)
	)
	var total_contribution := normal_contribution + knockback_contribution

	if is_zero_approx(total_contribution):
		_normal_velocity += correction
		return

	_normal_velocity += correction * (normal_contribution / total_contribution)
	_knockback.apply_velocity_correction(
		correction * (knockback_contribution / total_contribution)
	)


func prepare_prediction(delta: float) -> void:
	if is_hit_stop_active():
		_effective_velocity = Vector2.ZERO
		_predicted_position = _body.global_position
		_resolved_position = _body.global_position
		return

	_effective_velocity = _normal_velocity + _knockback.get_velocity()
	_predicted_position = _body.global_position + _effective_velocity * delta
	_resolved_position = _predicted_position


func set_resolved_position(position: Vector2) -> void:
	_resolved_position = position


func apply_resolved_position(delta: float) -> void:
	if is_hit_stop_active():
		_effective_velocity = Vector2.ZERO
		return

	_body.global_position = _resolved_position
	if delta <= 0.0:
		_effective_velocity = Vector2.ZERO
		return

	_effective_velocity = (_body.global_position - _frame_start_position) / delta


func get_current_position() -> Vector2:
	return _body.global_position


func get_predicted_position() -> Vector2:
	return _predicted_position


func get_base_effective_velocity() -> Vector2:
	if is_hit_stop_active():
		return Vector2.ZERO

	return _normal_velocity + _knockback.get_velocity()


func get_effective_velocity() -> Vector2:
	if is_hit_stop_active():
		return Vector2.ZERO

	return _effective_velocity


func get_effective_inverse_mass() -> float:
	if is_hit_stop_active():
		return 0.0

	return _motion_modifiers.get_effective_inverse_mass()


func is_hit_stop_active() -> bool:
	return _hit_stop.is_active()


func _get_effective_max_speed() -> float:
	return _stats.max_speed * _motion_modifiers.get_speed_multiplier()
