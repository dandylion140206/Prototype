class_name EnemyOverlayPanel
extends DebugOverlayPanel

@export var enemy_crowd_system: EnemyCrowdSystem


func update_display() -> void:
	if enemy_crowd_system == null:
		text = "Enemies: -"
		return

	text = "Enemies: %d" % [enemy_crowd_system.get_agent_count()]
