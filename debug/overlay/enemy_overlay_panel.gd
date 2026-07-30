class_name EnemyOverlayPanel
extends DebugOverlayPanel

@export var coin_raid_route: CoinRaidRoute


func update_display() -> void:
	if coin_raid_route == null:
		text = "Enemies: -"
		return

	text = (
		"Enemies: %d\nCrowd agents: %d\nCrowd pairs: %d"
		% [
			coin_raid_route.get_enemy_count(),
			coin_raid_route.get_crowd_agent_count(),
			coin_raid_route.get_crowd_pair_count(),
		]
	)
