class_name EnemyHardCoreSolver
extends Node

@onready var _crowd_solver: EnemyCrowdSolver = %EnemyCrowdSolver


func _physics_process(_delta: float) -> void:
	var active_enemies := _crowd_solver.get_active_enemies()
	var iteration_count := _get_iteration_count(active_enemies)

	for _iteration in iteration_count:
		_solve_iteration(active_enemies)


func _get_iteration_count(active_enemies: Array[Enemy]) -> int:
	var iteration_count := 0
	for enemy in active_enemies:
		iteration_count = maxi(
			iteration_count,
			enemy.get_enemy_movement().hard_core_iterations
		)

	return iteration_count


func _solve_iteration(active_enemies: Array[Enemy]) -> void:
	for first_index in active_enemies.size():
		var first_enemy := active_enemies[first_index]
		if not _is_active(first_enemy):
			continue

		for second_index in range(first_index + 1, active_enemies.size()):
			var second_enemy := active_enemies[second_index]
			if not _is_active(second_enemy):
				continue

			_solve_pair(first_enemy, second_enemy)


func _solve_pair(first_enemy: Enemy, second_enemy: Enemy) -> void:
	var first_movement := first_enemy.get_enemy_movement()
	var second_movement := second_enemy.get_enemy_movement()
	var minimum_distance := (
		first_movement.hard_core_radius + second_movement.hard_core_radius
	)
	var offset := first_enemy.global_position - second_enemy.global_position
	var distance := offset.length()
	if distance >= minimum_distance:
		return

	var normal := _get_pair_normal(
		first_enemy.get_instance_id(),
		second_enemy.get_instance_id(),
		offset
	)
	var correction := normal * (minimum_distance - distance) * 0.5
	first_enemy.global_position += correction
	second_enemy.global_position -= correction


func _is_active(enemy: Enemy) -> bool:
	return enemy != null and not enemy.is_queued_for_deletion() and enemy.visible


func _get_pair_normal(
	first_id: int,
	second_id: int,
	offset: Vector2
) -> Vector2:
	if not offset.is_zero_approx():
		return offset.normalized()

	var id_difference := float(first_id - second_id)
	return Vector2.from_angle(fposmod(id_difference * 0.61803398875, TAU))
