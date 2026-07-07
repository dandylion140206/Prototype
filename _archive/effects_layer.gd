extends Node2D

@export_range(0.0, 10000.0, 10.0) var trail_disable_speed: float = 200.0
@export_range(0.0, 10000.0, 10.0) var trail_enable_speed: float = 300.0
@export_range(0.0, 10000.0, 10.0) var trail_max_lifetime_speed: float = 5000.0
@export_range(0.0, 1.0, 0.01) var min_active_point_lifetime: float = 0.04
@export_range(0.0, 1.0, 0.01) var max_point_lifetime: float = 0.08
@export_range(0.0, 2.0, 0.01) var lifetime_increase_transition_duration: float = 0.2
@export_range(0.0, 2.0, 0.01) var lifetime_decrease_transition_duration: float = 0.01
@export_range(0.0, 1.0, 0.001) var lifetime_update_threshold: float = 0.01

@export var boost_gradient: Gradient
@export_range(0.0, 2.0, 0.01) var boost_color_duration: float = 0.25
@export_range(0.0, 2.0, 0.01) var boost_gradient_transition_duration: float = 0.05
@export_range(0.0, 2.0, 0.01) var normal_gradient_transition_duration: float = 0.2

var _is_trail_active := false
var _target_point_lifetime := 0.0
var _normal_gradient: Gradient
var _is_boost_color_active := false
var _boost_color_time_remaining := 0.0

@onready var _trail: Trail = $Trail


func _process(delta: float) -> void:
	_update_boost_color(delta)


func setup(ball: Ball) -> void:
	assert(ball != null, "ball must not be null.")
	assert(_trail != null, "Trail child node must not be null.")
	assert(boost_gradient != null, "boost_gradient must not be null.")
	assert(
		trail_disable_speed <= trail_enable_speed,
		"trail_disable_speed must be less than or equal to trail_enable_speed."
	)
	assert(
		trail_enable_speed <= trail_max_lifetime_speed,
		"trail_enable_speed must be less than or equal to trail_max_lifetime_speed."
	)
	assert(
		min_active_point_lifetime <= max_point_lifetime,
		"min_active_point_lifetime must be less than or equal to max_point_lifetime."
	)

	_normal_gradient = _trail.gradient
	_trail.target = ball
	_is_trail_active = false
	_target_point_lifetime = 0.0
	_trail.set_point_lifetime(0.0)


func update_ball_speed(speed: float) -> void:
	var current_speed := maxf(speed, 0.0)

	if _is_trail_active:
		if current_speed <= trail_disable_speed:
			_set_trail_active(false)
			return

		_update_active_trail_lifetime(current_speed)
		return

	if current_speed >= trail_enable_speed:
		_set_trail_active(true)
		_update_active_trail_lifetime(current_speed)


func on_ball_boosted() -> void:
	_is_boost_color_active = true
	_boost_color_time_remaining = boost_color_duration

	_trail.transition_trail_gradient(
		boost_gradient,
		boost_gradient_transition_duration
	)


func _set_trail_active(active: bool) -> void:
	if _is_trail_active == active:
		return

	_is_trail_active = active

	if not _is_trail_active:
		_apply_target_point_lifetime(0.0)


func _update_active_trail_lifetime(speed: float) -> void:
	var target_lifetime := _calculate_point_lifetime(speed)
	_apply_target_point_lifetime(target_lifetime)


func _calculate_point_lifetime(speed: float) -> float:
	if trail_max_lifetime_speed <= trail_enable_speed:
		return max_point_lifetime

	var progress := inverse_lerp(
		trail_enable_speed,
		trail_max_lifetime_speed,
		speed
	)

	progress = clampf(progress, 0.0, 1.0)

	return lerpf(
		min_active_point_lifetime,
		max_point_lifetime,
		progress
	)


func _apply_target_point_lifetime(value: float) -> void:
	var new_target := maxf(value, 0.0)

	if absf(new_target - _target_point_lifetime) < lifetime_update_threshold:
		return

	var transition_duration := lifetime_decrease_transition_duration

	if new_target > _target_point_lifetime:
		transition_duration = lifetime_increase_transition_duration

	_target_point_lifetime = new_target

	_trail.transition_point_lifetime(
		_target_point_lifetime,
		transition_duration
	)


func _update_boost_color(delta: float) -> void:
	if not _is_boost_color_active:
		return

	_boost_color_time_remaining -= delta

	if _boost_color_time_remaining > 0.0:
		return

	_is_boost_color_active = false
	_boost_color_time_remaining = 0.0

	_trail.transition_trail_gradient(
		_normal_gradient,
		normal_gradient_transition_duration
	)
