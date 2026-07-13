class_name ImpactAttack
extends Node

signal hit_landed(hit_data: HitData)

@export_range(0.0, 100.0, 1.0) var base_damage: float = 1.0
@export_range(0.0, 10.0, 0.1) var damage_add_per_100_speed: float = 1.2
@export_range(0.0, 1000.0, 1.0) var min_damage: float = 0.0
@export_range(0.0, 1000.0, 1.0) var max_damage: float = 100.0

@export_range(0.0, 20000.0, 100.0) var min_hit_stop_speed: float = 1000.0
@export_range(0.0, 0.5, 0.001) var attacker_hit_stop_duration: float = 0.01
@export_range(0.0, 0.5, 0.001) var target_hit_stop_duration: float = 0.01

var _get_speed: Callable


func setup(get_speed: Callable) -> void:
	assert(get_speed.is_valid(), "get_speed must be valid.")
	assert(min_damage <= max_damage, "min_damage must be less than or equal to max_damage.")
	_get_speed = get_speed


func apply_hit(hurtbox: Hurtbox) -> void:
	assert(_get_speed.is_valid(), "ImpactAttack must be setup before apply_hit().")

	if hurtbox == null:
		return

	var speed: float = _get_speed.call()
	var hit_data := HitData.new(
		_calculate_damage(speed),
		speed,
		_get_hit_stop_duration(speed, attacker_hit_stop_duration),
		_get_hit_stop_duration(speed, target_hit_stop_duration)
	)

	hurtbox.receive_hit(hit_data)
	hit_landed.emit(hit_data)


func _calculate_damage(speed: float) -> float:
	var damage_per_speed := damage_add_per_100_speed / 100.0
	var damage := base_damage + speed * damage_per_speed
	return clampf(damage, min_damage, max_damage)


func _get_hit_stop_duration(speed: float, duration: float) -> float:
	if speed < min_hit_stop_speed:
		return 0.0

	return duration
