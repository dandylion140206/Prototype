class_name Hitbox
extends Area2D

@export_range(1, 256, 1) var max_sweep_results: int = 64

@onready var _shape_cast: ShapeCast2D = %ShapeCast2D


func _ready() -> void:
	_shape_cast.max_results = max_sweep_results
	_shape_cast.collide_with_areas = true
	_shape_cast.collide_with_bodies = false


func get_overlapping_hurtboxes() -> Array[Hurtbox]:
	return _get_hurtboxes_at_motion(Vector2.ZERO, [])


func find_first_hurtboxes(
	motion: Vector2,
	excluded_hurtboxes: Array[Hurtbox]
) -> Dictionary:
	var hurtboxes := _get_hurtboxes_at_motion(motion, excluded_hurtboxes)
	if hurtboxes.is_empty():
		return {}

	var unsafe_fraction := _shape_cast.get_closest_collision_unsafe_fraction()
	var distance_epsilon := 1.0
	var max_contact_distance := motion.length() * unsafe_fraction + distance_epsilon
	var first_hurtboxes: Array[Hurtbox] = []

	for collision_index in _shape_cast.get_collision_count():
		var hurtbox := _shape_cast.get_collider(collision_index) as Hurtbox
		if hurtbox == null or not hurtboxes.has(hurtbox):
			continue

		var collision_offset := _shape_cast.get_collision_point(collision_index) - global_position
		if collision_offset.dot(motion.normalized()) <= max_contact_distance:
			if not first_hurtboxes.has(hurtbox):
				first_hurtboxes.append(hurtbox)

	if first_hurtboxes.is_empty():
		first_hurtboxes = hurtboxes

	return {
		"hurtboxes": first_hurtboxes,
		"unsafe_fraction": unsafe_fraction,
	}


func _get_hurtboxes_at_motion(
	motion: Vector2,
	excluded_hurtboxes: Array[Hurtbox]
) -> Array[Hurtbox]:
	_shape_cast.clear_exceptions()
	for hurtbox in excluded_hurtboxes:
		if hurtbox != null and is_instance_valid(hurtbox):
			_shape_cast.add_exception(hurtbox)

	_shape_cast.target_position = motion
	_shape_cast.force_shapecast_update()

	var hurtboxes: Array[Hurtbox] = []
	for collision_index in _shape_cast.get_collision_count():
		var hurtbox := _shape_cast.get_collider(collision_index) as Hurtbox
		if hurtbox == null or hurtbox.is_queued_for_deletion():
			continue

		if not hurtboxes.has(hurtbox):
			hurtboxes.append(hurtbox)

	_shape_cast.clear_exceptions()
	return hurtboxes
