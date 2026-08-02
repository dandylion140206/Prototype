class_name EnemyDestination
extends Node

var _destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false
var _target: Node2D


func _ready() -> void:
	process_physics_priority = -20


func _physics_process(_delta: float) -> void:
	if _target == null:
		return

	if is_instance_valid(_target):
		_destination = _target.global_position
		return

	_target = null


func set_destination(destination: Vector2) -> void:
	_destination = destination
	_has_destination = true
	_target = null


func set_target(target: Node2D) -> void:
	assert(target != null, "target must not be null.")

	_target = target
	_destination = target.global_position
	_has_destination = true


func clear() -> void:
	_target = null
	_has_destination = false


func has_destination() -> bool:
	return _has_destination


func get_destination() -> Vector2:
	return _destination
