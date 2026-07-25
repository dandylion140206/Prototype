class_name EnemyOverlayPanel
extends DebugOverlayPanel

var enemy_count_provider: Callable = Callable()
var active_enemy_count_provider: Callable = Callable()


func update_display() -> void:
	if not enemy_count_provider.is_valid() or not active_enemy_count_provider.is_valid():
		text = "Enemies: -"
		return

	text = "Enemies: %d (active %d)" % [
		int(enemy_count_provider.call()),
		int(active_enemy_count_provider.call()),
	]
