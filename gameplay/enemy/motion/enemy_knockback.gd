class_name EnemyKnockback
extends Node

@export_group("Impact")
@export_range(0.0, 10000.0, 1.0, "or_greater") var base_speed: float = 100.0
@export_range(0.0, 10.0, 0.01, "or_greater") var impact_speed_scale: float = 0.12
@export_range(0.0, 5000.0, 10.0, "or_greater") var max_speed: float = 800.0

@export_group("Decay")
@export_range(0.001, 2.0, 0.001, "or_greater") var duration: float = 0.18
@export var transition_type := Tween.TRANS_QUAD
@export var ease_type := Tween.EASE_OUT

var _motion_modifiers: EnemyMotionModifierStack
var _knockback_velocity := Vector2.ZERO
var _decay_start_velocity := Vector2.ZERO
var _decay_elapsed: float = 0.0
var _is_decaying: bool = false


func setup(motion_modifiers: EnemyMotionModifierStack) -> void:
	assert(motion_modifiers != null, "motion_modifiers must not be null.")
	assert(base_speed >= 0.0, "base_speed must not be negative.")
	assert(impact_speed_scale >= 0.0, "impact_speed_scale must not be negative.")
	assert(max_speed >= 0.0, "max_speed must not be negative.")
	assert(duration > 0.0, "duration must be greater than zero.")
	_motion_modifiers = motion_modifiers


func apply_knockback(
	impact_velocity: Vector2,
	impact_position: Vector2,
	enemy_position: Vector2
) -> void:
	if impact_velocity.is_zero_approx():
		return

	assert(_motion_modifiers != null, "EnemyKnockback must be setup before use.")

	var direction := (enemy_position - impact_position).normalized()
	if direction.is_zero_approx():
		direction = impact_velocity.normalized()

	var knockback_speed := base_speed + impact_velocity.length() * impact_speed_scale
	var added_velocity := (
		direction
		* knockback_speed
		* _motion_modifiers.get_effective_inverse_mass()
	)

	_knockback_velocity = (_knockback_velocity + added_velocity).limit_length(max_speed)
	_decay_start_velocity = _knockback_velocity
	_decay_elapsed = 0.0
	_is_decaying = not _knockback_velocity.is_zero_approx()


func update_decay(delta: float) -> void:
	if not _is_decaying:
		return

	if delta <= 0.0:
		return

	_decay_elapsed = minf(_decay_elapsed + delta, duration)
	_knockback_velocity = Vector2(
		Tween.interpolate_value(
			_decay_start_velocity,
			-_decay_start_velocity,
			_decay_elapsed,
			duration,
			transition_type,
			ease_type
		)
	)

	if _decay_elapsed >= duration:
		_knockback_velocity = Vector2.ZERO
		_is_decaying = false


func get_velocity() -> Vector2:
	return _knockback_velocity
