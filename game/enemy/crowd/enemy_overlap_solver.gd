class_name EnemyOverlapSolver
extends Node

## ペア列挙は反復の前に一度だけ行うため、反復中の押し出しで新たに接触する分の
## 余裕を検索距離へ加える。
@export_range(0.0, 2.0, 0.05) var pair_search_margin_ratio: float = 0.5

var _crowd_system: EnemyCrowdSystem
var _agents: Array[EnemyCrowdAgent] = []
var _grid: NeighborGrid = NeighborGrid.new()
var _positions: PackedVector2Array = PackedVector2Array()
var _initial_positions: PackedVector2Array = PackedVector2Array()
var _instance_ids: PackedInt64Array = PackedInt64Array()
var _overlap_radii: PackedFloat32Array = PackedFloat32Array()
var _inverse_masses: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	# EnemyMovement による移動の適用後に押し出しを解決する。
	process_physics_priority = 10
	set_physics_process(false)


func setup(crowd_system: EnemyCrowdSystem) -> void:
	assert(crowd_system != null, "crowd_system must not be null.")

	_crowd_system = crowd_system

	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	solve(_crowd_system.get_active_agents())


func solve(agents: Array[EnemyCrowdAgent]) -> void:
	_agents = agents

	var agent_count := _agents.size()
	if agent_count < 2:
		return

	var max_radius := 0.0
	var iteration_count := 0
	_build_snapshots(agent_count)
	for index in agent_count:
		max_radius = maxf(max_radius, _overlap_radii[index])
		iteration_count = maxi(iteration_count, _agents[index].stats.overlap_iterations)

	if max_radius <= 0.0 or iteration_count <= 0:
		return

	var pair_distance := max_radius * 2.0 * (1.0 + pair_search_margin_ratio)
	_grid.build(_positions, pair_distance)
	_grid.collect_pairs(pair_distance)

	for _iteration in iteration_count:
		_solve_iteration()

	_apply_positions(agent_count)


func _build_snapshots(agent_count: int) -> void:
	_positions.resize(agent_count)
	_initial_positions.resize(agent_count)
	_instance_ids.resize(agent_count)
	_overlap_radii.resize(agent_count)
	_inverse_masses.resize(agent_count)

	for index in agent_count:
		var agent := _agents[index]
		var stats := agent.stats
		var position := agent.get_position()

		_positions[index] = position
		_initial_positions[index] = position
		_instance_ids[index] = agent.get_instance_id()
		_overlap_radii[index] = stats.overlap_radius
		_inverse_masses[index] = stats.get_inverse_mass()


func _solve_iteration() -> void:
	var pairs := _grid.get_pairs()
	var pair_count := _grid.get_pair_count()

	for pair_index in pair_count:
		var a_index := pairs[pair_index * 2]
		var b_index := pairs[pair_index * 2 + 1]
		var minimum_distance := _overlap_radii[a_index] + _overlap_radii[b_index]
		var offset := _positions[a_index] - _positions[b_index]
		var distance_squared := offset.length_squared()
		if distance_squared >= minimum_distance * minimum_distance:
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

		var correction := normal * (minimum_distance - distance)
		_positions[a_index] += correction * (a_inverse_mass / total_inverse_mass)
		_positions[b_index] -= correction * (b_inverse_mass / total_inverse_mass)


func _apply_positions(agent_count: int) -> void:
	for index in agent_count:
		var position := _positions[index]
		if position == _initial_positions[index]:
			continue

		_agents[index].set_position(position)
