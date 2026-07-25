class_name EnemyMovement
extends Node

@export_range(0.0, 10000.0, 1.0) var target_speed: float = 100.0
@export_range(0.0, 10000.0, 1.0) var acceleration: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_speed: float = 400.0
@export_range(0.0, 1000.0, 0.1) var arrival_distance: float = 2.0
@export_range(0.0, 10.0, 0.01) var seek_weight: float = 1.0
@export_range(0.0, 10.0, 0.01) var wander_weight: float = 0.2
@export_range(0.0, 90.0, 0.1, "degrees") var wander_strength: float = 20.0
@export_range(0.0, 20.0, 0.1) var wander_speed: float = 2.0
@export_range(0.0, 100000.0, 1.0) var separation_weight: float = 600.0
@export_range(0.0, 1000.0, 1.0) var separation_radius: float = 100.0
@export_range(0.0, 100000.0, 1.0) var max_separation_acceleration: float = 900.0
@export_range(0.0, 1000.0, 0.1) var crowd_damping: float = 12.0
@export_range(0.0, 100000.0, 1.0) var max_crowd_damping_acceleration: float = 1200.0
@export_range(0.0, 1000.0, 1.0) var hard_core_radius: float = 24.0
@export_range(1, 8, 1) var hard_core_iterations: int = 3
@export_range(0.0, 10000.0, 1.0) var max_knockback_speed: float = 1500.0
@export_range(0.0, 100000.0, 1.0) var knockback_deceleration: float = 6000.0
@export_range(0.0, 1000.0, 1.0) var knockback_stop_speed: float = 10.0

var _body: CharacterBody2D
var _hit_stop: HitStop
var _fixed_destination: Vector2 = Vector2.ZERO
var _has_fixed_destination: bool = false
var _destination_target: Node2D
var _last_destination_target_position: Vector2 = Vector2.ZERO
var _has_last_destination_target_position: bool = false
var _wander_time: float = 0.0
var _wander_phase: float = 0.0
var _is_movement_stopped: bool = false
var _normal_velocity: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _pending_knockback_velocity: Vector2 = Vector2.ZERO
var _crowd_acceleration: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _body == null or _hit_stop == null:
		return

	if _hit_stop.is_active() or _is_movement_stopped:
		return

	_apply_pending_knockback()
	var destination: Variant = _get_destination()
	if destination == null:
		_normal_velocity = Vector2.ZERO
	else:
		_update_normal_velocity(destination as Vector2, delta)

	_body.velocity = _normal_velocity + _knockback_velocity
	_body.move_and_slide()
	_decay_knockback(delta)


func setup(body: CharacterBody2D, hit_stop: HitStop) -> void:
	assert(body != null, "body must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")

	_body = body
	_hit_stop = hit_stop
	_wander_phase = randf_range(0.0, TAU)


func set_destination(destination: Vector2) -> void:
	_fixed_destination = destination
	_has_fixed_destination = true
	_is_movement_stopped = false


func set_destination_target(destination_target: Node2D) -> void:
	assert(destination_target != null, "destination_target must not be null.")

	_destination_target = destination_target
	_last_destination_target_position = destination_target.global_position
	_has_last_destination_target_position = true
	_is_movement_stopped = false


func clear_destination_target() -> void:
	_destination_target = null

	if not _has_fixed_destination:
		stop()


func clear_destination() -> void:
	_destination_target = null
	_has_fixed_destination = false
	_has_last_destination_target_position = false
	stop()


func stop() -> void:
	_is_movement_stopped = true
	_normal_velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_pending_knockback_velocity = Vector2.ZERO

	if _body != null:
		_body.velocity = Vector2.ZERO


func add_knockback(knockback_velocity: Vector2) -> void:
	_pending_knockback_velocity = (
		_pending_knockback_velocity + knockback_velocity
	).limit_length(max_knockback_speed)


func set_crowd_acceleration(crowd_acceleration: Vector2) -> void:
	_crowd_acceleration = crowd_acceleration


func get_normal_velocity() -> Vector2:
	return _normal_velocity


func get_external_knockback_velocity() -> Vector2:
	return (_knockback_velocity + _pending_knockback_velocity).limit_length(
		max_knockback_speed
	)


func _get_destination() -> Variant:
	if _destination_target != null:
		if is_instance_valid(_destination_target):
			_last_destination_target_position = _destination_target.global_position
			_has_last_destination_target_position = true
			return _last_destination_target_position

		if _has_last_destination_target_position:
			_fixed_destination = _last_destination_target_position
			_has_fixed_destination = true

		_destination_target = null

	if _has_fixed_destination:
		return _fixed_destination

	return null


func _update_normal_velocity(destination: Vector2, delta: float) -> void:
	var to_destination := destination - _body.global_position
	var is_arrived := to_destination.length() <= arrival_distance
	var steering := Vector2.ZERO

	if not is_arrived:
		var seek_direction := to_destination.normalized()
		steering += seek_direction * seek_weight
		steering += _get_wander_force(seek_direction, delta) * wander_weight

	var desired_velocity := steering.limit_length(1.0) * target_speed
	_normal_velocity = _normal_velocity.move_toward(desired_velocity, acceleration * delta)
	_normal_velocity += _crowd_acceleration * delta
	_normal_velocity = _normal_velocity.limit_length(max_speed)


func _apply_pending_knockback() -> void:
	if _pending_knockback_velocity.is_zero_approx():
		return

	_knockback_velocity = (
		_knockback_velocity + _pending_knockback_velocity
	).limit_length(max_knockback_speed)
	_pending_knockback_velocity = Vector2.ZERO


func _decay_knockback(delta: float) -> void:
	_knockback_velocity = _knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_deceleration * delta
	)
	if _knockback_velocity.length() < knockback_stop_speed:
		_knockback_velocity = Vector2.ZERO


func _get_wander_force(seek_direction: Vector2, delta: float) -> Vector2:
	_wander_time += delta

	var base_direction := seek_direction
	if base_direction.is_zero_approx() and not _body.velocity.is_zero_approx():
		base_direction = _body.velocity.normalized()

	var wander_angle := sin(
		_wander_time * wander_speed + _wander_phase
	) * deg_to_rad(wander_strength)

	return base_direction.rotated(wander_angle)
