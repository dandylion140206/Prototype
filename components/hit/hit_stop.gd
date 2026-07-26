class_name HitStop
extends Node

@export_range(0, 60, 1) var restart_cooldown_frames: int = 0

var _start_physics_frame: int = -1
var _end_physics_frame: int = -1
var _restart_available_physics_frame: int = 0


func start(frame_count: int) -> bool:
	if frame_count <= 0:
		return false

	var current_frame := Engine.get_physics_frames()

	if _has_scheduled_hit_stop(current_frame):
		return false

	if current_frame < _restart_available_physics_frame:
		return false

	_start_physics_frame = current_frame + 1
	_end_physics_frame = _start_physics_frame + frame_count
	_restart_available_physics_frame = (
		_end_physics_frame + restart_cooldown_frames
	)
	return true


func cancel() -> void:
	_start_physics_frame = -1
	_end_physics_frame = -1
	_restart_available_physics_frame = Engine.get_physics_frames()


func cancel_deferred() -> void:
	cancel.call_deferred()


func is_active() -> bool:
	var current_frame := Engine.get_physics_frames()

	if _start_physics_frame < 0:
		return false

	if current_frame < _start_physics_frame:
		return false

	if current_frame >= _end_physics_frame:
		return false

	return true


func is_in_cooldown() -> bool:
	var current_frame := Engine.get_physics_frames()

	if _has_scheduled_hit_stop(current_frame):
		return false

	return current_frame < _restart_available_physics_frame


func get_remaining_frames() -> int:
	var current_frame := Engine.get_physics_frames()

	if not _has_scheduled_hit_stop(current_frame):
		return 0

	var effective_start_frame := maxi(
		current_frame,
		_start_physics_frame
	)
	return maxi(
		_end_physics_frame - effective_start_frame,
		0
	)


func _has_scheduled_hit_stop(current_frame: int) -> bool:
	if _start_physics_frame < 0:
		return false

	if current_frame >= _end_physics_frame:
		return false

	return true
