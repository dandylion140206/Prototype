class_name EnemyCrowdSeparationSolver
extends Node

var _agents: Array[EnemyCrowdAgent] = []
var _grid := EnemyCrowdNeighborGrid.new()
var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _instance_ids := PackedInt64Array()
var _separation_radii := PackedFloat32Array()
var _separation_strengths := PackedFloat32Array()
var _approach_dampings := PackedFloat32Array()
var _max_separation_accelerations := PackedFloat32Array()
var _max_approach_damping_accelerations := PackedFloat32Array()
var _inverse_masses := PackedFloat32Array()
var _separation_accelerations := PackedVector2Array()
var _approach_damping_accelerations := PackedVector2Array()


func solve(agents: Array[EnemyCrowdAgent], delta: float) -> void:
	_agents = agents
	var agent_count := _agents.size()
	if agent_count == 0:
		return

	var maximum_pair_distance := _build_snapshots(agent_count)
	if agent_count >= 2 and maximum_pair_distance > 0.0:
		_grid.build(_positions, maximum_pair_distance)
		_grid.collect_pairs(maximum_pair_distance)
		_accumulate_pair_accelerations(delta)

	_apply_accelerations(agent_count)


func get_pair_count() -> int:
	return _grid.get_pair_count()


func _build_snapshots(agent_count: int) -> float:
	_positions.resize(agent_count)
	_velocities.resize(agent_count)
	_instance_ids.resize(agent_count)
	_separation_radii.resize(agent_count)
	_separation_strengths.resize(agent_count)
	_approach_dampings.resize(agent_count)
	_max_separation_accelerations.resize(agent_count)
	_max_approach_damping_accelerations.resize(agent_count)
	_inverse_masses.resize(agent_count)
	_separation_accelerations.resize(agent_count)
	_approach_damping_accelerations.resize(agent_count)

	var maximum_radius := 0.0
	for index in agent_count:
		var agent := _agents[index]
		var stats := agent.crowd_stats
		_positions[index] = agent.get_current_position()
		_velocities[index] = agent.get_crowd_velocity()
		_instance_ids[index] = agent.get_instance_id()
		_separation_radii[index] = stats.separation_radius
		_separation_strengths[index] = stats.separation_strength
		_approach_dampings[index] = stats.approach_damping
		_max_separation_accelerations[index] = stats.max_separation_acceleration
		_max_approach_damping_accelerations[index] = (
			stats.max_approach_damping_acceleration
		)
		_inverse_masses[index] = agent.get_inverse_mass()
		_separation_accelerations[index] = Vector2.ZERO
		_approach_damping_accelerations[index] = Vector2.ZERO
		maximum_radius = maxf(maximum_radius, stats.separation_radius)

	return maximum_radius * 2.0


func _accumulate_pair_accelerations(delta: float) -> void:
	var pairs := _grid.get_pairs()
	var pair_count := _grid.get_pair_count()

	for pair_index in pair_count:
		var a_index := pairs[pair_index * 2]
		var b_index := pairs[pair_index * 2 + 1]
		var pair_radius := _separation_radii[a_index] + _separation_radii[b_index]
		if pair_radius <= 0.0:
			continue

		var offset := _positions[a_index] - _positions[b_index]
		var distance_squared := offset.length_squared()
		if distance_squared >= pair_radius * pair_radius:
			continue

		var distance := sqrt(distance_squared)
		var normal := _get_pair_normal(offset, distance, a_index, b_index)
		var compression := clampf(1.0 - distance / pair_radius, 0.0, 1.0)
		var pair_strength := (
			_separation_strengths[a_index] + _separation_strengths[b_index]
		) * 0.5
		var separation_force := normal * compression * compression * pair_strength
		var a_inverse_mass := _inverse_masses[a_index]
		var b_inverse_mass := _inverse_masses[b_index]
		_separation_accelerations[a_index] += separation_force * a_inverse_mass
		_separation_accelerations[b_index] -= separation_force * b_inverse_mass

		var total_inverse_mass := a_inverse_mass + b_inverse_mass
		if total_inverse_mass <= 0.0 or delta <= 0.0:
			continue

		var relative_velocity := _velocities[a_index] - _velocities[b_index]
		var closing_speed := maxf(0.0, -relative_velocity.dot(normal))
		if closing_speed <= 0.0:
			continue

		var pair_damping := (
			_approach_dampings[a_index] + _approach_dampings[b_index]
		) * 0.5
		var damping_force := closing_speed * pair_damping * compression
		var max_non_reversing_force := closing_speed / (delta * total_inverse_mass)
		damping_force = minf(damping_force, max_non_reversing_force)
		_approach_damping_accelerations[a_index] += (
			normal * damping_force * a_inverse_mass
		)
		_approach_damping_accelerations[b_index] -= (
			normal * damping_force * b_inverse_mass
		)


func _apply_accelerations(agent_count: int) -> void:
	for index in agent_count:
		var separation_acceleration := _separation_accelerations[index].limit_length(
			_max_separation_accelerations[index]
		)
		var approach_damping_acceleration := (
			_approach_damping_accelerations[index].limit_length(
				_max_approach_damping_accelerations[index]
			)
		)
		_agents[index].apply_crowd_acceleration(
			separation_acceleration + approach_damping_acceleration
		)


func _get_pair_normal(
	offset: Vector2,
	distance: float,
	a_index: int,
	b_index: int
) -> Vector2:
	if distance > 0.0:
		return offset / distance

	var id_mix := float(_instance_ids[a_index]) * 0.7548776662466927
	id_mix += float(_instance_ids[b_index]) * 0.5698402909980532
	return Vector2.from_angle(fposmod(id_mix, TAU))
