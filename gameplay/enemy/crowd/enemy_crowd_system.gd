class_name EnemyCrowdSystem
extends Node

var _registry := EnemyRegistry.new()
var _active_agents: Array[EnemyCrowdAgent] = []
var _crowd_pair_count: int = 0

@onready var _separation_solver: EnemyCrowdSeparationSolver = $SeparationSolver
@onready var _overlap_solver: EnemyCrowdOverlapSolver = $OverlapSolver


func register(agent: EnemyCrowdAgent) -> void:
	assert(agent != null, "agent must not be null.")
	_registry.register(agent)


func unregister(agent: EnemyCrowdAgent) -> void:
	_registry.unregister(agent)


func begin_frame() -> void:
	_active_agents.clear()
	_crowd_pair_count = 0

	for agent in _registry.get_agents():
		if agent == null or not is_instance_valid(agent) or agent.is_queued_for_deletion():
			continue

		_active_agents.append(agent)


func solve_separation() -> void:
	_separation_solver.solve(_active_agents)
	_crowd_pair_count = _separation_solver.get_pair_count()


func solve_overlap() -> void:
	_overlap_solver.solve(_active_agents)


func get_agent_count() -> int:
	return _registry.get_agents().size()


func get_crowd_pair_count() -> int:
	return _crowd_pair_count
