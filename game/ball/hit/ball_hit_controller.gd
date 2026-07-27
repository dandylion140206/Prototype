class_name BallHitController
extends Node

var _contacting_hurtbox_ids: Dictionary[int, bool] = {}

@onready var _hitbox: BallHitbox = $BallHitbox
@onready var _attack: BallAttack = $Attack


func setup(attack_source: Node2D) -> void:
	assert(attack_source != null, "attack_source must not be null.")

	_attack.setup(attack_source)


func apply_hits(planned_motion: Vector2, impact_velocity: Vector2) -> Array[HitData]:
	var hit_data_list: Array[HitData] = []
	var processed_hurtbox_ids: Dictionary[int, bool] = {}
	var excluded_hurtboxes: Array[Hurtbox] = []

	for collision in _hitbox.get_overlap_collisions():
		_process_collision(collision, impact_velocity, processed_hurtbox_ids, hit_data_list)
		excluded_hurtboxes.append(collision.hurtbox)

	if planned_motion.is_zero_approx():
		return hit_data_list

	while true:
		var sweep_result := _hitbox.sweep(planned_motion, excluded_hurtboxes)

		if sweep_result.collisions.is_empty():
			break

		var exclusion_count := excluded_hurtboxes.size()

		for collision in sweep_result.collisions:
			_process_collision(collision, impact_velocity, processed_hurtbox_ids, hit_data_list)

			if not excluded_hurtboxes.has(collision.hurtbox):
				excluded_hurtboxes.append(collision.hurtbox)

		if excluded_hurtboxes.size() == exclusion_count:
			break

	return hit_data_list


func update_contacting_hurtboxes() -> void:
	var current_contact_ids: Dictionary[int, bool] = {}

	for collision in _hitbox.get_overlap_collisions():
		current_contact_ids[
			collision.hurtbox.get_instance_id()
		] = true

	_contacting_hurtbox_ids = current_contact_ids


func _process_collision(
	collision: BallHitCollision,
	impact_velocity: Vector2,
	processed_hurtbox_ids: Dictionary[int, bool],
	hit_data_list: Array[HitData]
) -> void:
	var hurtbox := collision.hurtbox
	var hurtbox_id := hurtbox.get_instance_id()

	if processed_hurtbox_ids.has(hurtbox_id):
		return

	processed_hurtbox_ids[hurtbox_id] = true

	if _contacting_hurtbox_ids.has(hurtbox_id):
		return

	var hit_data := _attack.apply_hit(hurtbox, impact_velocity, collision.position)

	if hit_data != null:
		hit_data_list.append(hit_data)
