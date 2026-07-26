class_name EnemyKnockback
extends Node

@export_range(0.0, 10000.0, 1.0) var base_speed: float = 300.0
@export_range(0.0, 10.0, 0.01) var impact_speed_scale: float = 0.15
@export_range(0.0, 5000.0, 10.0) var max_speed: float = 1500.0
@export_range(0.0, 10000.0, 1.0) var deceleration: float = 6000.0
@export_range(0.0, 1000.0, 1.0) var stop_speed: float = 10.0

var _stats: EnemyBodyStats
var _hit_stop: HitStop
var _velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_physics_priority = 0
	set_physics_process(false)


func setup(stats: EnemyBodyStats, hit_stop: HitStop) -> void:
	assert(stats != null, "stats must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")

	_stats = stats
	_hit_stop = hit_stop

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _hit_stop.is_active() or _velocity.is_zero_approx():
		return

	_velocity = _velocity.move_toward(Vector2.ZERO, deceleration * delta)

	if _velocity.length() < stop_speed:
		_velocity = Vector2.ZERO


func apply_impact(
	impact_velocity: Vector2,
	impact_position: Vector2,
	target_position: Vector2
) -> void:
	if impact_velocity.is_zero_approx():
		return

	var direction := (target_position - impact_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT

	var impact_speed := impact_velocity.length()
	var knockback_speed := base_speed + impact_speed * impact_speed_scale
	var impulse := direction * knockback_speed

	_velocity = (
		_velocity + impulse * _stats.get_inverse_mass()
	).limit_length(max_speed)


func get_velocity() -> Vector2:
	return _velocity
