class_name EnemyCrowdOverlapSolver
extends Node

@export_range(0.0, 2.0, 0.05, "or_greater") var pair_search_margin_ratio: float = 0.5

const PENETRATION_TOLERANCE: float = 0.5

var _agents: Array[EnemyCrowdAgent] = []
var _grid := EnemyCrowdNeighborGrid.new()
var _positions := PackedVector2Array()
var _instance_ids := PackedInt64Array()
var _overlap_radii := PackedFloat32Array()
var _inverse_masses := PackedFloat32Array()
var _unresolved_overlap_count: int = 0
var _max_unresolved_penetration: float = 0.0


func solve(agents: Array[EnemyCrowdAgent]) -> void:
	_agents = agents
	_grid.clear_pairs()
	_unresolved_overlap_count = 0
	_max_unresolved_penetration = 0.0

	var agent_count := _agents.size()
	_build_snapshots(agent_count)
	for index in range(agent_count):
		_agents[index].set_resolved_position(_positions[index])

	if agent_count < 2:
		return

	var maximum_radius := 0.0
	var iteration_count := 0
	for index in range(agent_count):
		maximum_radius = maxf(maximum_radius, _overlap_radii[index])
		iteration_count = maxi(iteration_count, _agents[index].get_overlap_iterations())

	var maximum_pair_distance := maximum_radius * 2.0
	if maximum_pair_distance <= 0.0 or iteration_count <= 0:
		return

	var pair_search_distance := maximum_pair_distance * (1.0 + pair_search_margin_ratio)
	_grid.build(_positions, pair_search_distance)
	_grid.collect_pairs(pair_search_distance)

	for _iteration in range(iteration_count):
		_solve_position_pairs(_grid.get_pairs(), _grid.get_pair_count())

	# 補正で発生した新しい接触だけを一度拾い、追加補正を行う。
	_grid.build(_positions, pair_search_distance)
	_grid.collect_pairs(pair_search_distance)
	_solve_position_pairs(_grid.get_pairs(), _grid.get_pair_count())

	# 追加補正で発生した接触を含めて、最終状態を計測する。
	_grid.build(_positions, pair_search_distance)
	_grid.collect_pairs(pair_search_distance)
	_measure_unresolved_overlap(_grid.get_pairs(), _grid.get_pair_count())

	for index in range(agent_count):
		_agents[index].set_resolved_position(_positions[index])


func get_unresolved_overlap_count() -> int:
	return _unresolved_overlap_count


func get_max_unresolved_penetration() -> float:
	return _max_unresolved_penetration


func _build_snapshots(agent_count: int) -> void:
	_positions.resize(agent_count)
	_instance_ids.resize(agent_count)
	_overlap_radii.resize(agent_count)
	_inverse_masses.resize(agent_count)

	for index in range(agent_count):
		var agent := _agents[index]
		_positions[index] = agent.get_predicted_position()
		_instance_ids[index] = agent.get_instance_id()
		_overlap_radii[index] = agent.crowd_stats.overlap_radius
		_inverse_masses[index] = agent.get_inverse_mass()


func _solve_position_pairs(pairs: PackedInt32Array, pair_count: int) -> void:
	for pair_index in range(pair_count):
		var a_index := pairs[pair_index * 2]
		var b_index := pairs[pair_index * 2 + 1]
		var minimum_distance := _overlap_radii[a_index] + _overlap_radii[b_index]
		if minimum_distance <= 0.0:
			continue

		var offset := _positions[a_index] - _positions[b_index]
		var distance_squared := offset.length_squared()
		var distance := sqrt(distance_squared)
		var penetration := minimum_distance - distance
		if penetration <= PENETRATION_TOLERANCE:
			continue

		var normal := _get_pair_normal(offset, distance, a_index, b_index)
		var a_inverse_mass := _inverse_masses[a_index]
		var b_inverse_mass := _inverse_masses[b_index]
		var total_inverse_mass := a_inverse_mass + b_inverse_mass
		if total_inverse_mass <= 0.0:
			continue

		var correction := normal * penetration
		_positions[a_index] += correction * (a_inverse_mass / total_inverse_mass)
		_positions[b_index] -= correction * (b_inverse_mass / total_inverse_mass)


func _measure_unresolved_overlap(
	pairs: PackedInt32Array,
	pair_count: int
) -> void:
	for pair_index in range(pair_count):
		var a_index := pairs[pair_index * 2]
		var b_index := pairs[pair_index * 2 + 1]
		var minimum_distance := _overlap_radii[a_index] + _overlap_radii[b_index]
		var distance := _positions[a_index].distance_to(_positions[b_index])
		var penetration := minimum_distance - distance
		if penetration <= PENETRATION_TOLERANCE:
			continue

		_unresolved_overlap_count += 1
		_max_unresolved_penetration = maxf(_max_unresolved_penetration, penetration)


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
