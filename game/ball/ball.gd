class_name Ball
extends Node2D

signal hit_landed(hit_data: HitData)
signal active_ability_activated

var _target_position: Vector2 = Vector2.ZERO
var _contacting_hurtbox_ids: Dictionary[int, bool] = {}

@onready var _hitbox: Hitbox = %Hitbox
@onready var _movement: Movement = %Movement
@onready var _impact_attack: ImpactAttack = %ImpactAttack
@onready var _hit_stop: HitStop = %HitStop
@onready var _ability_controller: AbilityController = %AbilityController
@onready var _physics_position_interpolator: PhysicsPositionInterpolator = (
	%PhysicsPositionInterpolator
)


func _ready() -> void:
	_movement.setup(self)
	_impact_attack.setup(_movement.get_speed, self)
	_physics_position_interpolator.setup(self)

	var ability_context := AbilityContext.new(
		self,
		_movement,
		_hit_stop.cancel_deferred,
		get_interpolated_global_position
	)

	_ability_controller.setup(ability_context)

	_ability_controller.active_ability_activated.connect(
		active_ability_activated.emit
	)

	_target_position = global_position


func _physics_process(delta: float) -> void:
	if _hit_stop.is_active():
		_physics_position_interpolator.record_position()
		return

	_movement.update_velocity(
		global_position,
		_target_position,
		delta
	)

	var planned_motion := _movement.get_velocity() * delta
	var overlapping_hurtboxes := _hitbox.get_overlapping_hurtboxes()
	var landed_hit_data := _apply_new_overlap_hits(
		overlapping_hurtboxes
	)

	landed_hit_data.append_array(
		_move_and_apply_swept_hits(
			planned_motion,
			overlapping_hurtboxes
		)
	)

	_update_contacting_hurtboxes()

	if not landed_hit_data.is_empty():
		_hit_stop.start(
			landed_hit_data.front().attacker_hit_stop_duration
		)

		for hit_data in landed_hit_data:
			hit_landed.emit(hit_data)

	_physics_position_interpolator.record_position()


func set_target_position(target_position: Vector2) -> void:
	_target_position = target_position


func request_active_ability() -> bool:
	return _ability_controller.try_activate()


func get_interpolated_global_position() -> Vector2:
	return _physics_position_interpolator.get_interpolated_global_position()


func _apply_new_overlap_hits(
	hurtboxes: Array[Hurtbox]
) -> Array[HitData]:
	var hit_data_list: Array[HitData] = []

	for hurtbox in hurtboxes:
		if _is_contacting(hurtbox):
			continue

		var hit_data := _apply_hit(hurtbox, global_position)
		if hit_data != null:
			hit_data_list.append(hit_data)

	return hit_data_list


func _move_and_apply_swept_hits(
	planned_motion: Vector2,
	initial_exclusions: Array[Hurtbox]
) -> Array[HitData]:
	var hit_data_list: Array[HitData] = []

	if planned_motion.is_zero_approx():
		return hit_data_list

	var excluded_hurtboxes: Array[Hurtbox] = []
	excluded_hurtboxes.append_array(initial_exclusions)

	while true:
		var sweep_result := _hitbox.find_first_hurtboxes(
			planned_motion,
			excluded_hurtboxes
		)

		if sweep_result.is_empty():
			break

		var first_hurtboxes: Array[Hurtbox] = sweep_result["hurtboxes"]
		var unsafe_fraction: float = sweep_result["unsafe_fraction"]
		var contact_position := global_position + planned_motion * clampf(
			unsafe_fraction,
			0.0,
			1.0
		)

		for hurtbox in first_hurtboxes:
			if not _is_contacting(hurtbox):
				var hit_data := _apply_hit(
					hurtbox,
					contact_position
				)

				if hit_data != null:
					hit_data_list.append(hit_data)

			if not excluded_hurtboxes.has(hurtbox):
				excluded_hurtboxes.append(hurtbox)

	global_position += planned_motion
	return hit_data_list


func _apply_hit(
	hurtbox: Hurtbox,
	impact_position: Vector2
) -> HitData:
	if hurtbox == null or hurtbox.is_queued_for_deletion():
		return null

	var direction := (
		hurtbox.global_position - impact_position
	).normalized()

	return _impact_attack.apply_hit(hurtbox, direction)


func _update_contacting_hurtboxes() -> void:
	var current_contact_ids: Dictionary[int, bool] = {}

	for hurtbox in _hitbox.get_overlapping_hurtboxes():
		current_contact_ids[hurtbox.get_instance_id()] = true

	_contacting_hurtbox_ids = current_contact_ids


func _is_contacting(hurtbox: Hurtbox) -> bool:
	return _contacting_hurtbox_ids.has(
		hurtbox.get_instance_id()
	)
