class_name TargetMovement
extends Node

signal exited

enum State {
	ENTERING,
	WAITING,
	EXITING,
}

@export_range(0.0, 10.0, 0.1) var wait_duration: float = 1.0
@export_range(0.0, 180.0, 1.0, "degrees") var exit_angle_range: float = 45.0
@export_range(0.0, 80.0, 1.0, "degrees") var wander_strength: float = 12.0
@export_range(0.0, 10.0, 0.1) var wander_speed: float = 1.5
@export_range(1.0, 100.0, 1.0) var arrival_distance: float = 12.0

var _body: Node2D
var _movement: Movement
var _viewport_size := Vector2.ZERO
var _spawn_margin := 0.0
var _target_radius := 0.0
var _goal_position := Vector2.ZERO
var _entry_direction := Vector2.ZERO
var _state := State.ENTERING
var _wait_elapsed := 0.0
var _wander_time := 0.0
var _wander_phase := 0.0
var _is_active := false


func setup(body: Node2D, movement: Movement) -> void:
	assert(body != null, "body must not be null.")
	assert(movement != null, "movement must not be null.")

	_body = body
	_movement = movement


func initialize(
	spawn_position: Vector2,
	goal_position: Vector2,
	viewport_size: Vector2,
	spawn_margin: float,
	target_radius: float
) -> void:
	assert(_body != null, "TargetMovement must be setup before initialize().")
	assert(_movement != null, "TargetMovement must be setup before initialize().")

	_body.global_position = spawn_position
	_goal_position = goal_position
	_viewport_size = viewport_size
	_spawn_margin = spawn_margin
	_target_radius = target_radius
	_entry_direction = (goal_position - spawn_position).normalized()
	_state = State.ENTERING
	_wait_elapsed = 0.0
	_wander_time = 0.0
	_wander_phase = randf_range(0.0, TAU)
	_is_active = true


func stop() -> void:
	_is_active = false
	_movement.set_velocity(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	match _state:
		State.ENTERING:
			_update_entering(delta)
		State.WAITING:
			_update_waiting(delta)
		State.EXITING:
			_update_exiting(delta)


func _update_entering(delta: float) -> void:
	if _body.global_position.distance_to(_goal_position) <= arrival_distance:
		_body.global_position = _goal_position
		_movement.set_velocity(Vector2.ZERO)
		_state = State.WAITING
		return

	_move_toward(_goal_position, delta)


func _update_waiting(delta: float) -> void:
	_movement.set_velocity(Vector2.ZERO)
	_wait_elapsed += delta

	if _wait_elapsed >= wait_duration:
		_start_exiting()


func _update_exiting(delta: float) -> void:
	_move_toward(_goal_position, delta)

	if _has_fully_left_viewport():
		_is_active = false
		_movement.set_velocity(Vector2.ZERO)
		exited.emit()


func _move_toward(target_position: Vector2, delta: float) -> void:
	var direction := (target_position - _body.global_position).normalized()
	var wandered_direction := _get_wandered_direction(direction, delta)

	_movement.update_velocity(
		_body.global_position,
		_body.global_position + wandered_direction,
		delta
	)
	_movement.move(delta)


func _get_wandered_direction(direction: Vector2, delta: float) -> Vector2:
	_wander_time += delta

	var wander_angle := sin(
		_wander_time * wander_speed + _wander_phase
	) * deg_to_rad(wander_strength)

	return direction.rotated(wander_angle)


func _start_exiting() -> void:
	var exit_angle := deg_to_rad(
		randf_range(-exit_angle_range, exit_angle_range)
	)
	var exit_direction := _entry_direction.rotated(exit_angle)
	var exit_distance := _viewport_size.length() + _spawn_margin + _target_radius

	_goal_position = _body.global_position + exit_direction * exit_distance
	_state = State.EXITING


func _has_fully_left_viewport() -> bool:
	var viewport_rect := Rect2(
		Vector2(-_spawn_margin, -_spawn_margin),
		_viewport_size + Vector2.ONE * _spawn_margin * 2.0
	)
	var closest_viewport_position := Vector2(
		clampf(
			_body.global_position.x,
			viewport_rect.position.x,
			viewport_rect.end.x
		),
		clampf(
			_body.global_position.y,
			viewport_rect.position.y,
			viewport_rect.end.y
		)
	)

	return _body.global_position.distance_squared_to(closest_viewport_position) > (
		_target_radius * _target_radius
	)
