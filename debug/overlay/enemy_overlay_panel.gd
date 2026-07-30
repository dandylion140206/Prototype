class_name EnemyOverlayPanel
extends DebugOverlayPanel

@export var wandering_enemy_system: WanderingEnemySystem


func update_display() -> void:
	if wandering_enemy_system == null:
		text = "Enemies: -"
		return

	text = (
		"Enemies: %d\nCrowd agents: %d\nCrowd pairs: %d"
		% [
			wandering_enemy_system.get_enemy_count(),
			wandering_enemy_system.get_crowd_agent_count(),
			wandering_enemy_system.get_crowd_pair_count(),
		]
	)
