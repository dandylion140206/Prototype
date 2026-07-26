class_name EnemyCrowdSystem
extends Node

var _registry: EnemyRegistry = EnemyRegistry.new()
var _active_agents: Array[EnemyCrowdAgent] = []

@onready var _crowd_solver: EnemyCrowdSolver = $CrowdSolver
@onready var _overlap_solver: EnemyOverlapSolver = $OverlapSolver


func _ready() -> void:
	# 群衆加速度を算出してから各 EnemyMovement が積分する。
	process_physics_priority = -10

	_overlap_solver.setup(self)


func _physics_process(delta: float) -> void:
	_collect_active_agents()
	if _active_agents.is_empty():
		return

	_crowd_solver.solve(_active_agents, delta)


func register(agent: EnemyCrowdAgent) -> void:
	_registry.register(agent)


func unregister(agent: EnemyCrowdAgent) -> void:
	_registry.unregister(agent)


func get_active_agents() -> Array[EnemyCrowdAgent]:
	return _active_agents


func get_agent_count() -> int:
	return _registry.get_agents().size()


func get_crowd_pair_count() -> int:
	return _crowd_solver.get_pair_count()


func _collect_active_agents() -> void:
	_active_agents.clear()

	for agent in _registry.get_agents():
		if not agent.is_active():
			continue

		_active_agents.append(agent)
