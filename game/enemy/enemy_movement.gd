class_name EnemyMovement
extends Node

@export_range(0.0, 10000.0, 1.0) var acceleration: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_speed: float = 400.0
@export_range(0.01, 100.0, 0.01, "or_greater") var mass: float = 1.0
@export var is_immovable: bool = false
@export_range(0.0, 100000.0, 1.0) var separation_weight: float = 600.0
@export_range(0.0, 1000.0, 1.0) var separation_radius: float = 100.0
@export_range(0.0, 100000.0, 1.0) var max_separation_acceleration: float = 900.0
@export_range(0.0, 1000.0, 0.1) var crowd_damping: float = 12.0
@export_range(0.0, 100000.0, 1.0) var max_crowd_damping_acceleration: float = 1200.0
@export_range(0.0, 1000.0, 1.0) var overlap_radius: float = 24.0
@export_range(1, 8, 1) var overlap_iterations: int = 3
@export_range(0.0, 10000.0, 1.0) var max_knockback_speed: float = 1500.0
@export_range(0.0, 100000.0, 1.0) var knockback_deceleration: float = 6000.0
@export_range(0.0, 1000.0, 1.0) var knockback_stop_speed: float = 10.0

var _body: CharacterBody2D
var _hit_stop: HitStop
var _destination: EnemyDestination
var _steering: EnemySteering
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
	var destination: Variant = _destination.get_destination()
	if destination == null:
		_normal_velocity = Vector2.ZERO
	else:
		_update_normal_velocity(destination as Vector2, delta)

	_body.velocity = _normal_velocity + _knockback_velocity
	_body.move_and_slide()
	_decay_knockback(delta)


func setup(
	body: CharacterBody2D,
	hit_stop: HitStop,
	destination: EnemyDestination,
	steering: EnemySteering
) -> void:
	assert(body != null, "body must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")
	assert(destination != null, "destination must not be null.")
	assert(steering != null, "steering must not be null.")

	_body = body
	_hit_stop = hit_stop
	_destination = destination
	_steering = steering


func start() -> void:
	_is_movement_stopped = false


func stop() -> void:
	_is_movement_stopped = true
	_normal_velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_pending_knockback_velocity = Vector2.ZERO

	if _body != null:
		_body.velocity = Vector2.ZERO


func add_knockback(knockback_velocity: Vector2) -> void:
	var applied_velocity := knockback_velocity * get_inverse_mass()
	if applied_velocity.is_zero_approx():
		return

	_pending_knockback_velocity = (
		_pending_knockback_velocity + applied_velocity
	).limit_length(max_knockback_speed)


func set_crowd_acceleration(crowd_acceleration: Vector2) -> void:
	_crowd_acceleration = crowd_acceleration


func get_inverse_mass() -> float:
	if is_immovable:
		return 0.0

	return 1.0 / maxf(mass, 0.0001)


func get_normal_velocity() -> Vector2:
	return _normal_velocity


func get_external_knockback_velocity() -> Vector2:
	return (_knockback_velocity + _pending_knockback_velocity).limit_length(
		max_knockback_speed
	)


func _update_normal_velocity(destination: Vector2, delta: float) -> void:
	var desired_velocity := _steering.get_desired_velocity(
		_body.global_position,
		_body.velocity,
		destination,
		delta
	)
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
