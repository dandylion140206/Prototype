class_name EnemyMovement
extends Node

@export_range(0.0, 1000.0, 1.0) var acceleration: float = 100.0
@export_range(0.0, 5000.0, 1.0) var max_speed: float = 400.0

var _stats: EnemyBodyStats
var _body: Node2D
var _hit_stop: HitStop
var _steering: EnemySteering
var _knockback: EnemyKnockback
var _destination: EnemyDestination
var _seek_velocity: Vector2 = Vector2.ZERO
var _crowd_velocity: Vector2 = Vector2.ZERO
var _crowd_acceleration: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_physics_priority = 0
	set_physics_process(false)


func setup(
	body: Node2D,
	body_stats: EnemyBodyStats,
	hit_stop: HitStop,
	destination: EnemyDestination,
	steering: EnemySteering,
	knockback: EnemyKnockback
) -> void:
	assert(body != null, "body must not be null.")
	assert(body_stats != null, "body_stats must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")
	assert(destination != null, "destination must not be null.")
	assert(steering != null, "steering must not be null.")
	assert(knockback != null, "knockback must not be null.")

	_body = body
	_stats = body_stats
	_hit_stop = hit_stop
	_destination = destination
	_steering = steering
	_knockback = knockback

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _hit_stop.is_active():
		# HitStop 中に届いた群衆加速度は破棄する。再開時に一括で効くのを防ぐ。
		_crowd_acceleration = Vector2.ZERO
		return

	_update_seek_velocity(delta)
	_update_crowd_velocity(delta)

	var velocity := _seek_velocity + _crowd_velocity + _knockback.get_velocity()
	_body.global_position += velocity * delta


func get_effective_velocity() -> Vector2:
	return _seek_velocity + _crowd_velocity


func apply_crowd_acceleration(value: Vector2) -> void:
	_crowd_acceleration = value


func _update_seek_velocity(delta: float) -> void:
	var desired_velocity := Vector2.ZERO
	if _destination.has_destination():
		desired_velocity = _steering.get_desired_velocity(
			_body.global_position,
			_destination.get_destination(),
			delta
		)

	_seek_velocity = _seek_velocity.move_toward(
		desired_velocity,
		acceleration * delta
	)
	_seek_velocity = _seek_velocity.limit_length(max_speed)


func _update_crowd_velocity(delta: float) -> void:
	_crowd_velocity += _crowd_acceleration * delta
	_crowd_acceleration = Vector2.ZERO

	_crowd_velocity = _crowd_velocity.move_toward(
		Vector2.ZERO,
		_stats.crowd_deceleration * delta
	)
	_crowd_velocity = _crowd_velocity.limit_length(_stats.max_crowd_speed)
