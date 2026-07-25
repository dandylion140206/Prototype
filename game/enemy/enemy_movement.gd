class_name EnemyMovement
extends Node

@export_range(0.0, 10000.0, 1.0) var target_speed: float = 100.0
@export_range(0.0, 10000.0, 1.0) var acceleration: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_speed: float = 400.0
@export_range(0.0, 1000.0, 0.1) var arrival_distance: float = 2.0
@export_range(0.0, 10.0, 0.01) var seek_weight: float = 1.0
@export_range(0.0, 10.0, 0.01) var wander_weight: float = 0.2
@export_range(0.0, 90.0, 0.1, "degrees") var wander_strength: float = 20.0
@export_range(0.0, 20.0, 0.1) var wander_speed: float = 2.0
@export_range(0.0, 10.0, 0.01) var separation_weight: float = 1.0
@export_range(0.0, 1000.0, 1.0) var separation_radius: float = 100.0
@export_range(0.0, 10000.0, 1.0) var max_knockback_speed: float = 1500.0
@export_range(0.0, 100000.0, 1.0) var knockback_deceleration: float = 6000.0
@export_range(0.0, 1000.0, 1.0) var knockback_stop_speed: float = 10.0
@export_range(0.0, 1.0, 0.01) var push_transfer_ratio: float = 0.5

var _body: CharacterBody2D
var _hit_stop: HitStop
var _fixed_destination: Vector2 = Vector2.ZERO
var _has_fixed_destination: bool = false
var _destination_target: Node2D
var _last_destination_target_position: Vector2 = Vector2.ZERO
var _has_last_destination_target_position: bool = false
var _wander_time: float = 0.0
var _wander_phase: float = 0.0
var _is_movement_stopped: bool = false
var _normal_velocity: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _pending_knockback_velocity: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _body == null or _hit_stop == null:
		return

	if _hit_stop.is_active() or _is_movement_stopped:
		return

	_apply_pending_knockback()
	var destination: Variant = _get_destination()
	if destination == null:
		_normal_velocity = Vector2.ZERO
	else:
		_update_normal_velocity(destination as Vector2, delta)

	_body.velocity = _normal_velocity + _knockback_velocity
	_body.move_and_slide()
	_transfer_collision_pushes()
	_decay_knockback(delta)


func setup(body: CharacterBody2D, hit_stop: HitStop) -> void:
	assert(body != null, "body must not be null.")
	assert(hit_stop != null, "hit_stop must not be null.")

	_body = body
	_hit_stop = hit_stop
	_wander_phase = randf_range(0.0, TAU)


func set_destination(destination: Vector2) -> void:
	_fixed_destination = destination
	_has_fixed_destination = true
	_is_movement_stopped = false


func set_destination_target(destination_target: Node2D) -> void:
	assert(destination_target != null, "destination_target must not be null.")

	_destination_target = destination_target
	_last_destination_target_position = destination_target.global_position
	_has_last_destination_target_position = true
	_is_movement_stopped = false


func clear_destination_target() -> void:
	_destination_target = null

	if not _has_fixed_destination:
		stop()


func clear_destination() -> void:
	_destination_target = null
	_has_fixed_destination = false
	_has_last_destination_target_position = false
	stop()


func stop() -> void:
	_is_movement_stopped = true
	_normal_velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_pending_knockback_velocity = Vector2.ZERO

	if _body != null:
		_body.velocity = Vector2.ZERO


func add_knockback(knockback_velocity: Vector2) -> void:
	_pending_knockback_velocity = (
		_pending_knockback_velocity + knockback_velocity
	).limit_length(max_knockback_speed)


func _get_destination() -> Variant:
	if _destination_target != null:
		if is_instance_valid(_destination_target):
			_last_destination_target_position = _destination_target.global_position
			_has_last_destination_target_position = true
			return _last_destination_target_position

		if _has_last_destination_target_position:
			_fixed_destination = _last_destination_target_position
			_has_fixed_destination = true

		_destination_target = null

	if _has_fixed_destination:
		return _fixed_destination

	return null


func _update_normal_velocity(destination: Vector2, delta: float) -> void:
	var to_destination := destination - _body.global_position
	var is_arrived := to_destination.length() <= arrival_distance
	var steering := _get_separation_force() * separation_weight

	if not is_arrived:
		var seek_direction := to_destination.normalized()
		steering += seek_direction * seek_weight
		steering += _get_wander_force(seek_direction, delta) * wander_weight

	var desired_velocity := steering.limit_length(1.0) * target_speed
	_normal_velocity = _normal_velocity.move_toward(desired_velocity, acceleration * delta)
	_normal_velocity = _normal_velocity.limit_length(max_speed)


func _apply_pending_knockback() -> void:
	if _pending_knockback_velocity.is_zero_approx():
		return

	_knockback_velocity = (
		_knockback_velocity + _pending_knockback_velocity
	).limit_length(max_knockback_speed)
	_pending_knockback_velocity = Vector2.ZERO


func _decay_knockback(delta: float) -> void:
	_knockback_velocity = _knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_deceleration * delta
	)
	if _knockback_velocity.length() < knockback_stop_speed:
		_knockback_velocity = Vector2.ZERO


func _transfer_collision_pushes() -> void:
	for collision_index in _body.get_slide_collision_count():
		var collision := _body.get_slide_collision(collision_index)
		var other_enemy := collision.get_collider() as Enemy
		if other_enemy == null or other_enemy.is_queued_for_deletion():
			continue

		var push_direction := -collision.get_normal()
		var normal_speed := _body.velocity.dot(push_direction)
		if normal_speed <= 0.0:
			continue

		other_enemy.receive_collision_push(
			push_direction * normal_speed * push_transfer_ratio
		)


func _get_wander_force(seek_direction: Vector2, delta: float) -> Vector2:
	_wander_time += delta

	var base_direction := seek_direction
	if base_direction.is_zero_approx() and not _body.velocity.is_zero_approx():
		base_direction = _body.velocity.normalized()

	var wander_angle := sin(
		_wander_time * wander_speed + _wander_phase
	) * deg_to_rad(wander_strength)

	return base_direction.rotated(wander_angle)


func _get_separation_force() -> Vector2:
	if separation_radius <= 0.0:
		return Vector2.ZERO

	var separation_force := Vector2.ZERO
	var separation_radius_squared := separation_radius * separation_radius

	for candidate_value: Node in get_tree().get_nodes_in_group("enemy"):
		var enemy := candidate_value as Enemy
		if enemy == null or enemy == _body or enemy.is_queued_for_deletion():
			continue

		var offset := _body.global_position - enemy.global_position
		var distance_squared := offset.length_squared()
		if distance_squared > separation_radius_squared:
			continue

		if is_zero_approx(distance_squared):
			var direction := Vector2.from_angle(float(enemy.get_instance_id()))
			separation_force += direction
			continue

		var distance := sqrt(distance_squared)
		var strength := 1.0 - distance / separation_radius
		separation_force += offset / distance * strength

	return separation_force
