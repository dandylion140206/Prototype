class_name EnemyOverlayPanel
extends DebugOverlayPanel

@export var enemy_population: EnemyPopulation


func update_display() -> void:
	if enemy_population == null:
		text = "Enemies: -"
		return

	text = (
		"Enemies: %d\nCrowd agents: %d\nCrowd pairs: %d"
		% [
			enemy_population.get_enemy_count(),
			enemy_population.get_crowd_agent_count(),
			enemy_population.get_crowd_pair_count(),
		]
	)
