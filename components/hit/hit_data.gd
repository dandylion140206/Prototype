class_name HitData
extends RefCounted

var damage: float
var impact_velocity: Vector2
var impact_position: Vector2
var attacker_hit_stop_duration: float
var target_hit_stop_duration: float
var attack_source_id: int


func _init(
	p_damage: float,
	p_impact_velocity: Vector2,
	p_impact_position: Vector2,
	p_attacker_hit_stop_duration: float,
	p_target_hit_stop_duration: float,
	p_attack_source_id: int
) -> void:
	assert(p_damage >= 0.0, "p_damage must not be negative.")
	assert(p_attacker_hit_stop_duration >= 0.0, "p_attacker_hit_stop_duration must not be negative.")
	assert(p_target_hit_stop_duration >= 0.0, "p_target_hit_stop_duration must not be negative.")
	assert(p_attack_source_id > 0, "p_attack_source_id must be positive.")

	damage = p_damage
	impact_velocity = p_impact_velocity
	impact_position = p_impact_position
	attacker_hit_stop_duration = p_attacker_hit_stop_duration
	target_hit_stop_duration = p_target_hit_stop_duration
	attack_source_id = p_attack_source_id
