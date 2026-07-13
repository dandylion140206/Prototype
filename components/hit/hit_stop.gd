class_name HitStop
extends Node

var _remaining_time: float = 0.0
var _is_active: bool = false


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	_remaining_time -= delta

	if _remaining_time <= 0.0:
		cancel()


func start(duration: float) -> void:
	if duration <= 0.0:
		return

	if _is_active and duration <= _remaining_time:
		return

	_remaining_time = duration
	_is_active = true


func cancel() -> void:
	_remaining_time = 0.0
	_is_active = false


func cancel_deferred() -> void:
	cancel.call_deferred()


func is_active() -> bool:
	return _is_active


func get_remaining_time() -> float:
	return _remaining_time
