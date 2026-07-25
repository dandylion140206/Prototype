class_name EnemyCrowdSolver
extends Node

var _enemies: Array[Enemy] = []
var _grid: NeighborGrid = NeighborGrid.new()
var _positions: PackedVector2Array = PackedVector2Array()
var _effective_velocities: PackedVector2Array = PackedVector2Array()
var _instance_ids: PackedInt64Array = PackedInt64Array()
var _separation_radii: PackedFloat32Array = PackedFloat32Array()
var _separation_weights: PackedFloat32Array = PackedFloat32Array()
var _crowd_dampings: PackedFloat32Array = PackedFloat32Array()
var _inverse_masses: PackedFloat32Array = PackedFloat32Array()
var _max_separation_accelerations: PackedFloat32Array = PackedFloat32Array()
var _max_damping_accelerations: PackedFloat32Array = PackedFloat32Array()
var _separation_accelerations: PackedVector2Array = PackedVector2Array()
var _damping_accelerations: PackedVector2Array = PackedVector2Array()


func solve(enemies: Array[Enemy], delta: float) -> void:
	_enemies = enemies

	var enemy_count := _enemies.size()
	if enemy_count == 0:
		return

	var max_separation_radius := _build_snapshots(enemy_count)
	if enemy_count >= 2 and max_separation_radius > 0.0:
		_grid.build(_positions, max_separation_radius)
		_grid.collect_pairs(max_separation_radius)
		_accumulate_pair_accelerations(delta)

	_apply_accelerations(enemy_count)


func _build_snapshots(enemy_count: int) -> float:
	_positions.resize(enemy_count)
	_effective_velocities.resize(enemy_count)
	_instance_ids.resize(enemy_count)
	_separation_radii.resize(enemy_count)
	_separation_weights.resize(enemy_count)
	_crowd_dampings.resize(enemy_count)
	_inverse_masses.resize(enemy_count)
	_max_separation_accelerations.resize(enemy_count)
	_max_damping_accelerations.resize(enemy_count)
	_separation_accelerations.resize(enemy_count)
	_damping_accelerations.resize(enemy_count)

	var max_separation_radius := 0.0
	for index in enemy_count:
		var enemy := _enemies[index]
		var movement := enemy.get_enemy_movement()

		_positions[index] = enemy.global_position
		_effective_velocities[index] = (
			movement.get_normal_velocity() + movement.get_external_knockback_velocity()
		)
		_instance_ids[index] = enemy.get_instance_id()
		_separation_radii[index] = movement.separation_radius
		_separation_weights[index] = movement.separation_weight
		_crowd_dampings[index] = movement.crowd_damping
		_inverse_masses[index] = movement.get_inverse_mass()
		_max_separation_accelerations[index] = movement.max_separation_acceleration
		_max_damping_accelerations[index] = movement.max_crowd_damping_acceleration
		_separation_accelerations[index] = Vector2.ZERO
		_damping_accelerations[index] = Vector2.ZERO

		max_separation_radius = maxf(max_separation_radius, movement.separation_radius)

	return max_separation_radius


func _accumulate_pair_accelerations(delta: float) -> void:
	var pairs := _grid.get_pairs()
	var pair_count := _grid.get_pair_count()
	var has_valid_delta := not is_zero_approx(delta)
	var inverse_delta := 1.0 / delta if has_valid_delta else 0.0

	for pair_index in pair_count:
		var a_index := pairs[pair_index * 2]
		var b_index := pairs[pair_index * 2 + 1]

		var pair_radius := maxf(_separation_radii[a_index], _separation_radii[b_index])
		var offset := _positions[a_index] - _positions[b_index]
		var distance_squared := offset.length_squared()
		if distance_squared >= pair_radius * pair_radius:
			continue

		var a_inverse_mass := _inverse_masses[a_index]
		var b_inverse_mass := _inverse_masses[b_index]
		var total_inverse_mass := a_inverse_mass + b_inverse_mass
		if total_inverse_mass <= 0.0:
			continue

		var distance := sqrt(distance_squared)
		var normal := Vector2.ZERO
		if distance > 0.0:
			normal = offset / distance
		else:
			var id_difference := float(_instance_ids[a_index] - _instance_ids[b_index])
			normal = Vector2.from_angle(fposmod(id_difference * 0.61803398875, TAU))

		var compression := 1.0 - distance / pair_radius
		var pair_weight := (
			_separation_weights[a_index] + _separation_weights[b_index]
		) * 0.5
		var separation_force := normal * compression * compression * pair_weight
		_separation_accelerations[a_index] += separation_force * a_inverse_mass
		_separation_accelerations[b_index] -= separation_force * b_inverse_mass

		if not has_valid_delta:
			continue

		var relative_velocity := (
			_effective_velocities[a_index] - _effective_velocities[b_index]
		)
		var closing_speed := maxf(0.0, -relative_velocity.dot(normal))
		if closing_speed <= 0.0:
			continue

		var pair_damping := (_crowd_dampings[a_index] + _crowd_dampings[b_index]) * 0.5
		var damping_force := minf(
			closing_speed * pair_damping * compression,
			closing_speed * inverse_delta / total_inverse_mass
		)
		_damping_accelerations[a_index] += normal * (damping_force * a_inverse_mass)
		_damping_accelerations[b_index] -= normal * (damping_force * b_inverse_mass)


func _apply_accelerations(enemy_count: int) -> void:
	for index in enemy_count:
		var separation_acceleration := _separation_accelerations[index].limit_length(
			_max_separation_accelerations[index]
		)
		var damping_acceleration := _damping_accelerations[index].limit_length(
			_max_damping_accelerations[index]
		)
		_enemies[index].set_crowd_acceleration(
			separation_acceleration + damping_acceleration
		)
