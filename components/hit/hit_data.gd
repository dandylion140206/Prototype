class_name HitData
extends RefCounted

var damage: float
var hit_speed: float
var attacker_hit_stop_duration: float
var target_hit_stop_duration: float


func _init(
	p_damage: float,
	p_hit_speed: float,
	p_attacker_hit_stop_duration: float,
	p_target_hit_stop_duration: float
) -> void:
	assert(p_damage >= 0.0, "p_damage must not be negative.")
	assert(p_hit_speed >= 0.0, "p_hit_speed must not be negative.")
	assert(p_attacker_hit_stop_duration >= 0.0, "p_attacker_hit_stop_duration must not be negative.")
	assert(p_target_hit_stop_duration >= 0.0, "p_target_hit_stop_duration must not be negative.")

	damage = p_damage
	hit_speed = p_hit_speed
	attacker_hit_stop_duration = p_attacker_hit_stop_duration
	target_hit_stop_duration = p_target_hit_stop_duration
