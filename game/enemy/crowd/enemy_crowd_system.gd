class_name EnemyCrowdSystem
extends Node

var _registry: EnemyRegistry = EnemyRegistry.new()
var _active_enemies: Array[Enemy] = []

@onready var _crowd_solver: EnemyCrowdSolver = $CrowdSolver
@onready var _overlap_solver: EnemyOverlapSolver = $OverlapSolver


func _physics_process(delta: float) -> void:
	_collect_active_enemies()
	if _active_enemies.is_empty():
		return

	_crowd_solver.solve(_active_enemies, delta)
	_overlap_solver.solve(_active_enemies)


func register(enemy: Enemy) -> void:
	_registry.register(enemy)


func unregister(enemy: Enemy) -> void:
	_registry.unregister(enemy)


func get_active_enemies() -> Array[Enemy]:
	return _active_enemies


func get_enemy_count() -> int:
	return _registry.get_enemies().size()


func get_crowd_pair_count() -> int:
	return _crowd_solver.get_pair_count()


func _collect_active_enemies() -> void:
	_active_enemies.clear()
	for enemy in _registry.get_enemies():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue

		if not enemy.visible:
			continue

		_active_enemies.append(enemy)
