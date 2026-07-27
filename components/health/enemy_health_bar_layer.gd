class_name EnemyHealthBarLayer
extends Node2D

@export var health_bar_offset: Vector2 = Vector2(0.0, -55.0)

var _health_bars: Dictionary = {}


func _process(_delta: float) -> void:
	for enemy_value: Variant in _health_bars.keys():
		var enemy := enemy_value as Enemy
		var health_bar := _health_bars[enemy] as HealthBar

		if not is_instance_valid(enemy) or not is_instance_valid(health_bar):
			remove_enemy(enemy)
			continue

		_update_health_bar_position(enemy, health_bar)


func add_enemy(enemy: Enemy) -> void:
	assert(enemy != null, "Enemy must not be null.")

	if _health_bars.has(enemy):
		return

	var health_bar := HealthBar.new()
	add_child(health_bar)

	_health_bars[enemy] = health_bar
	enemy.health_changed.connect(_on_enemy_health_changed.bind(enemy))
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))

	health_bar.update_health(enemy.get_current_health(), enemy.get_max_health())
	_update_health_bar_position(enemy, health_bar)


func remove_enemy(enemy: Enemy) -> void:
	if not _health_bars.has(enemy):
		return

	var health_bar := _health_bars[enemy] as HealthBar
	_health_bars.erase(enemy)

	if is_instance_valid(health_bar):
		health_bar.queue_free()


func _on_enemy_health_changed(current_health: float, max_health: float, enemy: Enemy) -> void:
	if not _health_bars.has(enemy):
		return

	var health_bar := _health_bars[enemy] as HealthBar
	health_bar.update_health(current_health, max_health)


func _on_enemy_died(enemy: Enemy) -> void:
	remove_enemy(enemy)


func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	remove_enemy(enemy)


func _update_health_bar_position(enemy: Enemy, health_bar: HealthBar) -> void:
	health_bar.global_position = enemy.global_position + health_bar_offset
