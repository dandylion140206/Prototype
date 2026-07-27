class_name HitData
extends RefCounted

var damage: float:
	get:
		return _damage
var impact_velocity: Vector2:
	get:
		return _impact_velocity
var impact_position: Vector2:
	get:
		return _impact_position
var attacker_hit_stop_frames: int:
	get:
		return _attacker_hit_stop_frames
var target_hit_stop_frames: int:
	get:
		return _target_hit_stop_frames
var attack_source_id: int:
	get:
		return _attack_source_id

var _damage: float
var _impact_velocity: Vector2
var _impact_position: Vector2
var _attacker_hit_stop_frames: int
var _target_hit_stop_frames: int
var _attack_source_id: int


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

	_damage = p_damage
	_impact_velocity = p_impact_velocity
	_impact_position = p_impact_position
	_attacker_hit_stop_frames = p_attacker_hit_stop_frames
	_target_hit_stop_frames = p_target_hit_stop_frames
	_attack_source_id = p_attack_source_id
