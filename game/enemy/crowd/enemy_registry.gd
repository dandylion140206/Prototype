class_name EnemyRegistry
extends RefCounted

var _agents: Array[EnemyCrowdAgent] = []


func register(agent: EnemyCrowdAgent) -> void:
	if agent == null or _agents.has(agent):
		return

	_agents.append(agent)
	agent.tree_exiting.connect(_on_agent_tree_exiting.bind(agent))


func unregister(agent: EnemyCrowdAgent) -> void:
	if agent == null:
		return

	var index := _agents.find(agent)
	if index < 0:
		return

	_agents.remove_at(index)

	if agent.tree_exiting.is_connected(_on_agent_tree_exiting):
		agent.tree_exiting.disconnect(_on_agent_tree_exiting)


func get_agents() -> Array[EnemyCrowdAgent]:
	return _agents


func _on_agent_tree_exiting(agent: EnemyCrowdAgent) -> void:
	unregister(agent)
