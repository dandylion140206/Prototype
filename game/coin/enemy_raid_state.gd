class_name EnemyRaidState
extends RefCounted

enum RaidPhase {
	APPROACHING,
	CARRYING,
	ESCAPED,
}

var phase: RaidPhase = RaidPhase.APPROACHING
var approach_target: Vector2
var approach_ratio: float = 0.5
var has_approach_target: bool = false
var is_carrying_coin: bool = false
var motion_modifier_id: int = -1
var carried_coin_visual: Node2D
