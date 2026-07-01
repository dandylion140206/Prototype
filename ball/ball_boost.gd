class_name BallBoost
extends Node2D

signal boost_used

@export_range(0.0, 5000.0, 10.0) var boost_speed: float = 1600.0
@export_range(0.0, 2.0, 0.01) var cooldown: float = 0.4

var _movement: Movement

@onready var cooldown_timer: Timer = $CooldownTimer


func setup(movement: Movement) -> void:
	assert(movement != null, "movement must not be null.")

	_movement = movement

	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = cooldown


func use() -> void:
	assert(_movement != null, "movement must be setup before use().")

	if not _can_use():
		return

	var velocity := _movement.get_velocity()

	if velocity.is_zero_approx():
		return

	var boost_velocity := velocity.normalized() * boost_speed

	_movement.add_velocity(boost_velocity)
	cooldown_timer.start()

	boost_used.emit()


func _can_use() -> bool:
	return cooldown_timer.is_stopped()
