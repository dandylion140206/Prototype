class_name ContactDamage
extends Node

signal hit_applied(speed: float)

@export_range(0.0, 100.0, 1.0) var base_damage: float = 1.0
@export_range(0.0, 10.0, 0.1) var damage_add_per_100_speed: float = 1.2
@export_range(0.0, 1000.0, 1.0) var min_damage: float = 0.0
@export_range(0.0, 1000.0, 1.0) var max_damage: float = 100.0

var _get_speed: Callable


func setup(get_speed: Callable) -> void:
	assert(get_speed.is_valid(), "get_speed must be a valid Callable.")
	assert(min_damage <= max_damage, "min_damage must be less than or equal to max_damage.")

	_get_speed = get_speed


func apply_hit(hurtbox: Hurtbox) -> void:
	assert(_get_speed.is_valid(), "ContactDamage must be setup before apply_hit().")

	if hurtbox == null:
		return

	var speed: float = _get_speed.call()
	var damage_amount := _calculate_damage(speed)

	hurtbox.receive_hit(damage_amount, speed)
	hit_applied.emit(speed)


func _calculate_damage(speed: float) -> float:
	var damage_add_per_speed := damage_add_per_100_speed / 100.0
	var damage_amount := base_damage + speed * damage_add_per_speed

	return clampf(damage_amount, min_damage, max_damage)
