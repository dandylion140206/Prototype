class_name EnemyKnockback
extends Node

@export_group("Impact")
@export_range(0.0, 10000.0, 1.0) var base_speed: float = 300.0
@export_range(0.0, 10.0, 0.01) var impact_speed_scale: float = 0.15
@export_range(0.0, 5000.0, 10.0) var max_speed: float = 270.0

@export_group("Decay")
@export_range(0.01, 2.0, 0.01) var duration: float = 0.12
@export var transition_type := Tween.TRANS_QUAD
@export var ease_type := Tween.EASE_IN

var _stats: EnemyBodyStats
var _hit_stop: HitStop
var _velocity := Vector2.ZERO
var _decay_tween: Tween


func setup(stats: EnemyBodyStats, hit_stop: HitStop) -> void:
	_stats = stats
	_hit_stop = hit_stop


func _physics_process(delta: float) -> void:
	if _hit_stop.is_active():
		return

	if _decay_tween != null:
		_decay_tween.custom_step(delta)


func apply_impact(
	impact_velocity: Vector2,
	impact_position: Vector2,
	target_position: Vector2
) -> void:
	if impact_velocity.is_zero_approx():
		return

	var direction := (
		target_position - impact_position
	).normalized()

	if direction.is_zero_approx():
		direction = Vector2.RIGHT

	var speed := (
		base_speed
		+ impact_velocity.length() * impact_speed_scale
	)

	var impulse := direction * speed

	_velocity = (
		_velocity
		+ impulse * _stats.get_inverse_mass()
	).limit_length(max_speed)

	_start_decay()


func get_velocity() -> Vector2:
	return _velocity


func _start_decay() -> void:
	if _decay_tween != null:
		_decay_tween.kill()

	_decay_tween = create_tween()
	_decay_tween.pause()

	_decay_tween.tween_property(
		self,
		^"_velocity",
		Vector2.ZERO,
		duration
	).set_trans(transition_type).set_ease(ease_type)
