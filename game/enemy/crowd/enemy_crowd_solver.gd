class_name EnemyCrowdSolver
extends Node

var _agents: Array[EnemyCrowdAgent] = []
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


func solve(agents: Array[EnemyCrowdAgent], delta: float) -> void:
	_agents = agents

	var agent_count := _agents.size()
	if agent_count == 0:
		return

	var max_separation_radius := _build_snapshots(agent_count)
	if agent_count >= 2 and max_separation_radius > 0.0:
		_grid.build(_positions, max_separation_radius)
		_grid.collect_pairs(max_separation_radius)
		_accumulate_pair_accelerations(delta)

	_apply_accelerations(agent_count)


func get_pair_count() -> int:
	return _grid.get_pair_count()


func _build_snapshots(agent_count: int) -> float:
	_positions.resize(agent_count)
	_effective_velocities.resize(agent_count)
	_instance_ids.resize(agent_count)
	_separation_radii.resize(agent_count)
	_separation_weights.resize(agent_count)
	_crowd_dampings.resize(agent_count)
	_inverse_masses.resize(agent_count)
	_max_separation_accelerations.resize(agent_count)
	_max_damping_accelerations.resize(agent_count)
	_separation_accelerations.resize(agent_count)
	_damping_accelerations.resize(agent_count)

	var max_separation_radius := 0.0
	for index in agent_count:
		var agent := _agents[index]
		var stats := agent.stats

		_positions[index] = agent.get_position()
		_effective_velocities[index] = agent.get_effective_velocity()
		_instance_ids[index] = agent.get_instance_id()
		_separation_radii[index] = stats.separation_radius
		_separation_weights[index] = stats.separation_weight
		_crowd_dampings[index] = stats.crowd_damping
		_inverse_masses[index] = agent.get_inverse_mass()
		_max_separation_accelerations[index] = stats.max_separation_acceleration
		_max_damping_accelerations[index] = stats.max_crowd_damping_acceleration
		_separation_accelerations[index] = Vector2.ZERO
		_damping_accelerations[index] = Vector2.ZERO

		max_separation_radius = maxf(max_separation_radius, stats.separation_radius)

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
		var pair_weight := (_separation_weights[a_index] + _separation_weights[b_index]) * 0.5
		var separation_force := normal * compression * compression * pair_weight
		_separation_accelerations[a_index] += separation_force * a_inverse_mass
		_separation_accelerations[b_index] -= separation_force * b_inverse_mass

		if not has_valid_delta:
			continue

		var relative_velocity := _effective_velocities[a_index] - _effective_velocities[b_index]
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


func _apply_accelerations(agent_count: int) -> void:
	for index in agent_count:
		var separation_acceleration := _separation_accelerations[index].limit_length(_max_separation_accelerations[index])
		var damping_acceleration := _damping_accelerations[index].limit_length(_max_damping_accelerations[index])
		_agents[index].apply_crowd_acceleration(separation_acceleration + damping_acceleration)
