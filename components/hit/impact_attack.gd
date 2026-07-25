class_name ImpactAttack
extends Node

signal hit_landed(hit_data: HitData)

@export_range(0.0, 100.0, 1.0) var base_damage: float = 1.0
@export_range(0.0, 10.0, 0.1) var damage_add_per_100_speed: float = 1.2
@export_range(0.0, 1000.0, 1.0) var min_damage: float = 0.0
@export_range(0.0, 1000.0, 1.0) var max_damage: float = 100.0

@export_range(0.0, 20000.0, 100.0) var min_hit_stop_speed: float = 1000.0
@export_range(0.0, 0.2, 0.001) var attacker_hit_stop_duration: float = 0.01
@export_range(0.0, 0.2, 0.001) var target_hit_stop_duration: float = 0.01
@export_range(0.0, 10000.0, 1.0) var base_knockback_speed: float = 300.0
@export_range(0.0, 10.0, 0.01) var knockback_speed_scale: float = 0.15
@export_range(0.0, 10000.0, 1.0) var max_knockback_speed: float = 1500.0

var _get_speed: Callable
var _attack_source: Node2D


func setup(get_speed: Callable, attack_source: Node2D) -> void:
	assert(get_speed.is_valid(), "get_speed must be valid.")
	assert(attack_source != null, "attack_source must not be null.")
	assert(min_damage <= max_damage, "min_damage must be less than or equal to max_damage.")
	_get_speed = get_speed
	_attack_source = attack_source


func apply_hit(hurtbox: Hurtbox, knockback_direction: Vector2) -> HitData:
	assert(_get_speed.is_valid(), "ImpactAttack must be setup before apply_hit().")
	assert(_attack_source != null, "ImpactAttack must be setup before apply_hit().")

	if hurtbox == null:
		return null

	var speed: float = _get_speed.call()
	var damage := _calculate_damage(speed)
	if damage <= 0.0:
		return null

	var direction := knockback_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT

	var knockback_speed := minf(
		base_knockback_speed + speed * knockback_speed_scale,
		max_knockback_speed
	)
	var hit_data := HitData.new(
		damage,
		speed,
		_get_hit_stop_duration(speed, attacker_hit_stop_duration),
		_get_hit_stop_duration(speed, target_hit_stop_duration),
		_attack_source.get_instance_id(),
		direction,
		direction * knockback_speed
	)

	if not hurtbox.receive_hit(hit_data):
		return null

	hit_landed.emit(hit_data)
	return hit_data


func _calculate_damage(speed: float) -> float:
	var damage_per_speed := damage_add_per_100_speed / 100.0
	var damage := base_damage + speed * damage_per_speed
	return clampf(damage, min_damage, max_damage)


func _get_hit_stop_duration(speed: float, duration: float) -> float:
	if speed < min_hit_stop_speed:
		return 0.0

	return duration
