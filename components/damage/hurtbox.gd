class_name Hurtbox
extends Area2D

signal hit_received(hit_speed: float)

var _health: Health


func setup(health: Health) -> void:
	assert(health != null, "health must not be null.")
	_health = health


func receive_hit(damage_amount: float, hit_speed: float) -> void:
	receive_damage(damage_amount)
	hit_received.emit(hit_speed)


func receive_damage(amount: float) -> void:
	assert(_health != null, "health must be setup before receive_damage().")

	if amount <= 0.0:
		return

	_health.damage(amount)


func set_enabled(enabled: bool) -> void:
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
