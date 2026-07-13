class_name BoostTrail
extends Node2D

@export_range(0.0, 1.0, 0.01) var boost_point_lifetime: float = 0.08
@export_range(0.0, 2.0, 0.01) var lifetime_increase_duration: float = 0.1
@export_range(0.0, 2.0, 0.01) var boost_trail_hold_duration: float = 0.1
@export_range(0.0, 2.0, 0.01) var lifetime_decrease_duration: float = 0.2

var _boost_trail_time_remaining := 0.0
var _is_boost_trail_active := false

@onready var trail: Trail = $Trail


func _process(delta: float) -> void:
	_update_boost_trail(delta)


func setup(
	source: Node2D,
	get_interpolated_position: Callable
) -> void:
	assert(source != null, "source must not be null.")
	assert(get_interpolated_position.is_valid(), "get_interpolated_position must be valid.")
	assert(trail != null, "Trail child node must not be null.")

	trail.setup(source, get_interpolated_position)
	trail.set_point_lifetime(0.0)
	trail.clear_trail()

	_boost_trail_time_remaining = 0.0
	_is_boost_trail_active = false


func play_boost_trail() -> void:
	_is_boost_trail_active = true
	_boost_trail_time_remaining = (
		lifetime_increase_duration
		+ boost_trail_hold_duration
	)

	trail.transition_point_lifetime(
		boost_point_lifetime,
		lifetime_increase_duration
	)


func _update_boost_trail(delta: float) -> void:
	if not _is_boost_trail_active:
		return

	_boost_trail_time_remaining -= delta

	if _boost_trail_time_remaining > 0.0:
		return

	_is_boost_trail_active = false
	_boost_trail_time_remaining = 0.0

	trail.transition_point_lifetime(
		0.0,
		lifetime_decrease_duration
	)


func stop_immediately() -> void:
	_is_boost_trail_active = false
	_boost_trail_time_remaining = 0.0
	trail.set_point_lifetime(0.0)
	trail.clear_trail()
