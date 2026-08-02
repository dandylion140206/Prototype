class_name EnemyRegistry
extends RefCounted

var _agents: Array[EnemyCrowdAgent] = []

## bind() で生成した Callable は毎回別インスタンスになり
## is_connected / disconnect の比較に使えないため保持する。
var _exit_callables: Dictionary[int, Callable] = {}


func register(agent: EnemyCrowdAgent) -> void:
	if agent == null or _agents.has(agent):
		return

	_agents.append(agent)

	var exit_callable := _on_agent_tree_exiting.bind(agent)
	_exit_callables[agent.get_instance_id()] = exit_callable
	agent.tree_exiting.connect(exit_callable)


func unregister(agent: EnemyCrowdAgent) -> void:
	if agent == null:
		return

	var index := _agents.find(agent)
	if index < 0:
		return

	_agents.remove_at(index)

	var agent_id := agent.get_instance_id()
	if not _exit_callables.has(agent_id):
		return

	var exit_callable := _exit_callables[agent_id]
	_exit_callables.erase(agent_id)

	if agent.tree_exiting.is_connected(exit_callable):
		agent.tree_exiting.disconnect(exit_callable)


func get_agents() -> Array[EnemyCrowdAgent]:
	return _agents


func _on_agent_tree_exiting(agent: EnemyCrowdAgent) -> void:
	unregister(agent)
