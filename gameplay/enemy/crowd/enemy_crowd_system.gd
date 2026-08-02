class_name EnemyCrowdSystem
extends Node

var _registry := EnemyRegistry.new()
var _active_agents: Array[EnemyCrowdAgent] = []
var _crowd_pair_count: int = 0
var _unresolved_overlap_count: int = 0
var _max_unresolved_penetration: float = 0.0

@onready var _separation_solver: EnemyCrowdSeparationSolver = $SeparationSolver
@onready var _overlap_solver: EnemyCrowdOverlapSolver = $OverlapSolver


func register(agent: EnemyCrowdAgent) -> void:
	assert(agent != null, "agent must not be null.")
	_registry.register(agent)


func unregister(agent: EnemyCrowdAgent) -> void:
	_registry.unregister(agent)


func begin_frame() -> Array[EnemyCrowdAgent]:
	_active_agents.clear()
	_crowd_pair_count = 0
	_unresolved_overlap_count = 0
	_max_unresolved_penetration = 0.0

	for agent in _registry.get_agents():
		if agent == null or not is_instance_valid(agent) or agent.is_queued_for_deletion():
			continue

		_active_agents.append(agent)

	return _active_agents


func solve_separation(delta: float) -> void:
	_separation_solver.solve(_active_agents, delta)
	_crowd_pair_count = _separation_solver.get_pair_count()


func solve_overlap() -> void:
	_overlap_solver.solve(_active_agents)
	_unresolved_overlap_count = _overlap_solver._get_unresolved_overlap_count()
	_max_unresolved_penetration = _overlap_solver._get_max_unresolved_penetration()


func get_active_agents() -> Array[EnemyCrowdAgent]:
	return _active_agents


func get_agent_count() -> int:
	return _registry.get_agents().size()


func get_crowd_pair_count() -> int:
	return _crowd_pair_count
