class_name EnemyCrowdSolver
extends Node


class CrowdState:
	var position: Vector2
	var normal_velocity: Vector2
	var external_knockback_velocity: Vector2

var _active_enemies: Array[Enemy] = []


func _physics_process(delta: float) -> void:
	_active_enemies = _collect_active_enemies()
	var snapshots := _create_snapshots(_active_enemies)

	for enemy in _active_enemies:
		enemy.set_crowd_acceleration(
			_calculate_crowd_acceleration(enemy, snapshots, delta)
		)


func get_active_enemies() -> Array[Enemy]:
	return _active_enemies


func _collect_active_enemies() -> Array[Enemy]:
	var active_enemies: Array[Enemy] = []
	for candidate_value: Node in get_tree().get_nodes_in_group("enemy"):
		var enemy := candidate_value as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or not enemy.visible:
			continue

		active_enemies.append(enemy)

	active_enemies.sort_custom(_sort_enemies_by_instance_id)
	return active_enemies


func _create_snapshots(active_enemies: Array[Enemy]) -> Dictionary[int, CrowdState]:
	var snapshots: Dictionary[int, CrowdState] = {}
	for enemy in active_enemies:
		var snapshot := CrowdState.new()
		snapshot.position = enemy.global_position
		snapshot.normal_velocity = enemy.get_normal_velocity()
		snapshot.external_knockback_velocity = enemy.get_external_knockback_velocity()
		snapshots[enemy.get_instance_id()] = snapshot

	return snapshots


func _calculate_crowd_acceleration(
	enemy: Enemy,
	snapshots: Dictionary[int, CrowdState],
	delta: float
) -> Vector2:
	var movement := enemy.get_enemy_movement()
	var self_snapshot: CrowdState = snapshots[enemy.get_instance_id()]
	var separation_acceleration := Vector2.ZERO
	var damping_acceleration := Vector2.ZERO

	if movement.separation_radius <= 0.0:
		return Vector2.ZERO

	for other_enemy_id in snapshots:
		if other_enemy_id == enemy.get_instance_id():
			continue

		var other_snapshot: CrowdState = snapshots[other_enemy_id]
		var offset := self_snapshot.position - other_snapshot.position
		var distance_squared := offset.length_squared()
		var radius_squared := movement.separation_radius * movement.separation_radius
		if distance_squared >= radius_squared:
			continue

		var distance := sqrt(distance_squared)
		var normal := _get_pair_normal(enemy.get_instance_id(), other_enemy_id, offset)
		var compression := 1.0 - distance / movement.separation_radius
		var separation_strength := compression * compression
		separation_acceleration += (
			normal * separation_strength * movement.separation_weight
		)

		var self_effective_velocity := (
			self_snapshot.normal_velocity
			+ self_snapshot.external_knockback_velocity
		)
		var other_effective_velocity := (
			other_snapshot.normal_velocity
			+ other_snapshot.external_knockback_velocity
		)
		var relative_velocity := self_effective_velocity - other_effective_velocity
		var closing_speed := maxf(0.0, -relative_velocity.dot(normal))
		if closing_speed <= 0.0 or is_zero_approx(delta):
			continue

		var requested_acceleration := (
			closing_speed * movement.crowd_damping * compression
		)
		var non_reversing_acceleration := closing_speed * 0.5 / delta
		damping_acceleration += normal * minf(
			requested_acceleration,
			non_reversing_acceleration
		)

	separation_acceleration = separation_acceleration.limit_length(
		movement.max_separation_acceleration
	)
	damping_acceleration = damping_acceleration.limit_length(
		movement.max_crowd_damping_acceleration
	)
	return separation_acceleration + damping_acceleration


func _get_pair_normal(
	self_id: int,
	other_id: int,
	offset: Vector2
) -> Vector2:
	if not offset.is_zero_approx():
		return offset.normalized()

	var id_difference := float(self_id - other_id)
	return Vector2.from_angle(fposmod(id_difference * 0.61803398875, TAU))


func _sort_enemies_by_instance_id(a: Enemy, b: Enemy) -> bool:
	return a.get_instance_id() < b.get_instance_id()
