class_name HitData
extends RefCounted

var damage: float
var impact_velocity: Vector2
var impact_position: Vector2
var attacker_hit_stop_frames: int
var target_hit_stop_frames: int
var attack_source_id: int


func _init(
	p_damage: float,
	p_impact_velocity: Vector2,
	p_impact_position: Vector2,
	p_attacker_hit_stop_frames: int,
	p_target_hit_stop_frames: int,
	p_attack_source_id: int
) -> void:
	assert(p_damage >= 0.0, "p_damage must not be negative.")
	assert(p_attacker_hit_stop_frames >= 0, "p_attacker_hit_stop_frames must not be negative.")
	assert(p_target_hit_stop_frames >= 0, "p_target_hit_stop_frames must not be negative.")
	assert(p_attack_source_id > 0, "p_attack_source_id must be positive.")

	damage = p_damage
	impact_velocity = p_impact_velocity
	impact_position = p_impact_position
	attacker_hit_stop_frames = p_attacker_hit_stop_frames
	target_hit_stop_frames = p_target_hit_stop_frames
	attack_source_id = p_attack_source_id
