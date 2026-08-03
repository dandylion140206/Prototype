class_name EnemyMotionSystem
extends Node

var _crowd_system: EnemyCrowdSystem
var _motors: Array[EnemyMotor] = []
var _exit_callables: Dictionary[int, Callable] = {}


func _ready() -> void:
	set_physics_process(false)


func setup(crowd_system: EnemyCrowdSystem) -> void:
	assert(crowd_system != null, "crowd_system must not be null.")
	_crowd_system = crowd_system
	set_physics_process(true)


func register(motor: EnemyMotor) -> void:
	assert(motor != null, "motor must not be null.")
	if _motors.has(motor):
		return

	_motors.append(motor)
	var exit_callable := _on_motor_tree_exiting.bind(motor)
	_exit_callables[motor.get_instance_id()] = exit_callable
	motor.tree_exiting.connect(exit_callable)


func unregister(motor: EnemyMotor) -> void:
	if motor == null:
		return

	var index := _motors.find(motor)
	if index < 0:
		return

	_motors.remove_at(index)
	var motor_id := motor.get_instance_id()
	if not _exit_callables.has(motor_id):
		return

	var exit_callable: Callable = _exit_callables[motor_id]
	_exit_callables.erase(motor_id)
	if motor.tree_exiting.is_connected(exit_callable):
		motor.tree_exiting.disconnect(exit_callable)


func get_motor_count() -> int:
	return _motors.size()


func _physics_process(delta: float) -> void:
	_collect_valid_motors()
	if _motors.is_empty():
		_crowd_system.begin_frame()
		return

	for motor in _motors:
		motor.begin_frame()

	for motor in _motors:
		motor.update_sources(delta)

	_crowd_system.begin_frame()
	_crowd_system.solve_separation()

	for motor in _motors:
		motor.prepare_prediction(delta)

	_crowd_system.solve_overlap()

	for motor in _motors:
		motor.apply_resolved_position(delta)


func _collect_valid_motors() -> void:
	var index := _motors.size() - 1
	while index >= 0:
		var motor := _motors[index]
		if motor == null or not is_instance_valid(motor) or motor.is_queued_for_deletion():
			_remove_motor_at(index)
		index -= 1


func _remove_motor_at(index: int) -> void:
	var motor := _motors[index]
	_motors.remove_at(index)
	if motor == null:
		return

	_exit_callables.erase(motor.get_instance_id())


func _on_motor_tree_exiting(motor: EnemyMotor) -> void:
	unregister(motor)
