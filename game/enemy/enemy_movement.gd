class_name EnemyMovement
extends Node

@export_range(0.0, 1000.0, 10.0) var acceleration: float = 100.0
@export_range(0.0, 1000.0, 10.0) var max_speed: float = 400.0

var _body: Node2D
var _hit_stop: HitStop
var _steering: EnemySteering
var _knockback: EnemyKnockback
var _destination: EnemyDestination
var _motion_modifiers: EnemyMotionModifierStack
var _seek_velocity: Vector2 = Vector2.ZERO
var _crowd_acceleration: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_physics_priority = 0
	set_physics_process(false)


func setup(
	body: Node2D,
	hit_stop: HitStop,
	destination: EnemyDestination,
	steering: EnemySteering,
	knockback: EnemyKnockback,
	motion_modifiers: EnemyMotionModifierStack
) -> void:
	assert(body != null, "body must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")
	assert(destination != null, "destination must not be null.")
	assert(steering != null, "steering must not be null.")
	assert(knockback != null, "knockback must not be null.")
	assert(motion_modifiers != null, "motion_modifiers must not be null.")

	_body = body
	_hit_stop = hit_stop
	_destination = destination
	_steering = steering
	_knockback = knockback
	_motion_modifiers = motion_modifiers

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _hit_stop.is_active():
		# HitStop 中に届いた群衆加速度は破棄する。再開時に一括で効くのを防ぐ。
		_crowd_acceleration = Vector2.ZERO
		return

	_update_seek_velocity(delta)

	var velocity := _seek_velocity + _knockback.get_velocity()
	_body.global_position += velocity * delta


func get_effective_velocity() -> Vector2:
	return _seek_velocity


func apply_crowd_acceleration(value: Vector2) -> void:
	_crowd_acceleration = value


func _update_seek_velocity(delta: float) -> void:
	var desired_velocity := Vector2.ZERO
	var speed_multiplier := _motion_modifiers.get_speed_multiplier()
	if _destination.has_destination():
		desired_velocity = _steering.get_desired_velocity(
			_body.global_position,
			_destination.get_destination(),
			delta
		)
		desired_velocity *= speed_multiplier

	_seek_velocity = _seek_velocity.move_toward(desired_velocity, acceleration * delta)
	_seek_velocity += _crowd_acceleration * delta
	_crowd_acceleration = Vector2.ZERO
	_seek_velocity = _seek_velocity.limit_length(max_speed * speed_multiplier)
