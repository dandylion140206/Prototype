class_name BallAttack
extends Node

@export_range(0.0, 100.0, 1.0) var base_damage: float = 1.0
@export_range(0.0, 10.0, 0.1) var damage_add_per_100_speed: float = 1.2
@export_range(0.0, 1000.0, 1.0) var min_damage: float = 0.0
@export_range(0.0, 1000.0, 1.0) var max_damage: float = 100.0

@export_range(0.0, 20000.0, 100.0) var min_hit_stop_speed: float = 1000.0
@export_range(0, 60, 1) var attacker_hit_stop_frames: int = 1
@export_range(0, 60, 1) var target_hit_stop_frames: int = 1

var _attack_source: Node2D


func setup(attack_source: Node2D) -> void:
	assert(attack_source != null, "attack_source must not be null.")
	assert(min_damage <= max_damage, "min_damage must be less than or equal to max_damage.")
	_attack_source = attack_source


func apply_hit(
	hurtbox: Hurtbox,
	impact_velocity: Vector2,
	impact_position: Vector2
) -> HitData:
	assert(_attack_source != null, "BallAttack must be setup before apply_hit().")

	if hurtbox == null:
		return null

	var speed := impact_velocity.length()
	var damage := _calculate_damage(speed)
	if damage <= 0.0:
		return null

	var hit_data := HitData.new(
		damage,
		impact_velocity,
		impact_position,
		_get_hit_stop_frames(speed, attacker_hit_stop_frames),
		_get_hit_stop_frames(speed, target_hit_stop_frames),
		_attack_source.get_instance_id()
	)

	if not hurtbox.receive_hit(hit_data):
		return null

	return hit_data


func _calculate_damage(speed: float) -> float:
	var damage_per_speed := damage_add_per_100_speed / 100.0
	var damage := base_damage + speed * damage_per_speed
	return clampf(damage, min_damage, max_damage)


func _get_hit_stop_frames(speed: float, frame_count: int) -> int:
	if speed < min_hit_stop_speed:
		return 0

	return frame_count
