class_name EnemyCrowdSeparationSolver
extends Node

var _agents: Array[EnemyCrowdAgent] = []
var _grid := EnemyCrowdNeighborGrid.new()
var _positions := PackedVector2Array()
var _base_velocities := PackedVector2Array()
var _instance_ids := PackedInt64Array()
var _inverse_masses := PackedFloat32Array()

var _separation_radii := PackedFloat32Array()
var _separation_speeds := PackedFloat32Array()
var _max_crowd_speeds := PackedFloat32Array()
var _approach_dampings := PackedFloat32Array()
var _max_approach_damping_speeds := PackedFloat32Array()

var _crowd_velocities := PackedVector2Array()


func solve(agents: Array[EnemyCrowdAgent]) -> void:
	_agents = agents
	_grid.clear_pairs()

	var agent_count := _agents.size()
	var maximum_pair_distance := _build_snapshots(agent_count)
	if agent_count >= 2 and maximum_pair_distance > 0.0:
		_grid.build(_positions, maximum_pair_distance)
		_grid.collect_pairs(maximum_pair_distance)
		_accumulate_pair_velocities()

	_apply_crowd_velocities(agent_count)


func get_pair_count() -> int:
	return _grid.get_pair_count()


func _build_snapshots(agent_count: int) -> float:
	_positions.resize(agent_count)
	_base_velocities.resize(agent_count)
	_instance_ids.resize(agent_count)
	_inverse_masses.resize(agent_count)
	_separation_radii.resize(agent_count)
	_separation_speeds.resize(agent_count)
	_max_crowd_speeds.resize(agent_count)
	_approach_dampings.resize(agent_count)
	_max_approach_damping_speeds.resize(agent_count)
	_crowd_velocities.resize(agent_count)

	var maximum_radius := 0.0
	for index in range(agent_count):
		var agent := _agents[index]
		var stats := agent.crowd_stats
		_positions[index] = agent.get_current_position()
		_base_velocities[index] = agent.get_base_velocity()
		_instance_ids[index] = agent.get_instance_id()
		_inverse_masses[index] = agent.get_inverse_mass()
		_separation_radii[index] = stats.separation_radius
		_separation_speeds[index] = stats.separation_speed
		_max_crowd_speeds[index] = stats.max_crowd_speed
		_approach_dampings[index] = stats.approach_damping
		_max_approach_damping_speeds[index] = stats.max_approach_damping_speed
		_crowd_velocities[index] = Vector2.ZERO
		maximum_radius = maxf(maximum_radius, stats.separation_radius)

	return maximum_radius * 2.0


func _accumulate_pair_velocities() -> void:
	var pairs := _grid.get_pairs()
	var pair_count := _grid.get_pair_count()

	for pair_index in range(pair_count):
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

		var a_inverse_mass := _inverse_masses[a_index]
		var b_inverse_mass := _inverse_masses[b_index]
		var total_inverse_mass := a_inverse_mass + b_inverse_mass
		if total_inverse_mass <= 0.0:
			continue

		var a_weight := a_inverse_mass / total_inverse_mass
		var b_weight := b_inverse_mass / total_inverse_mass
		var pair_speed := (
			(_separation_speeds[a_index] + _separation_speeds[b_index])
			* 0.5
			* compression
			* compression
		)

		_crowd_velocities[a_index] += normal * pair_speed * a_weight * 2.0
		_crowd_velocities[b_index] -= normal * pair_speed * b_weight * 2.0

		var relative_velocity := _base_velocities[a_index] - _base_velocities[b_index]
		var closing_speed := maxf(0.0, -relative_velocity.dot(normal))
		if closing_speed <= 0.0:
			continue

		var pair_damping := (
			_approach_dampings[a_index] + _approach_dampings[b_index]
		) * 0.5
		var max_pair_damping_speed := (
			_max_approach_damping_speeds[a_index]
			+ _max_approach_damping_speeds[b_index]
		) * 0.5
		var damping_speed := minf(
			closing_speed * pair_damping * compression,
			max_pair_damping_speed
		)

		_crowd_velocities[a_index] += normal * damping_speed * a_weight
		_crowd_velocities[b_index] -= normal * damping_speed * b_weight


func _apply_crowd_velocities(agent_count: int) -> void:
	for index in range(agent_count):
		var crowd_velocity := _crowd_velocities[index].limit_length(
			_max_crowd_speeds[index]
		)
		_agents[index].set_crowd_velocity(crowd_velocity)


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
