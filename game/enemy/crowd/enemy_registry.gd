class_name EnemyRegistry
extends RefCounted

var _enemies: Array[Enemy] = []


func register(enemy: Enemy) -> void:
	if enemy == null or _enemies.has(enemy):
		return

	_enemies.append(enemy)
	enemy.died.connect(_on_enemy_removed.bind(enemy))
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))


func unregister(enemy: Enemy) -> void:
	if enemy == null:
		return

	var index := _enemies.find(enemy)
	if index < 0:
		return

	_enemies.remove_at(index)

	if enemy.died.is_connected(_on_enemy_removed):
		enemy.died.disconnect(_on_enemy_removed)

	if enemy.tree_exiting.is_connected(_on_enemy_removed):
		enemy.tree_exiting.disconnect(_on_enemy_removed)


func get_enemies() -> Array[Enemy]:
	return _enemies


func _on_enemy_removed(enemy: Enemy) -> void:
	unregister(enemy)
