class_name BallHitbox
extends Area2D

@export_range(1, 256, 1) var max_sweep_results: int = 64

@onready var _shape_cast: ShapeCast2D = $ShapeCast2D


func _ready() -> void:
	_shape_cast.max_results = max_sweep_results
	_shape_cast.collision_mask = collision_mask
	_shape_cast.collide_with_areas = true
	_shape_cast.collide_with_bodies = false


func get_overlap_collisions() -> Array[BallHitCollision]:
	return _get_collisions_at_motion(Vector2.ZERO, [])


func sweep(motion: Vector2, excluded_hurtboxes: Array[Hurtbox]) -> HitSweepResult:
	var collisions := _get_collisions_at_motion(motion, excluded_hurtboxes)
	var unsafe_fraction := 1.0

	if not collisions.is_empty():
		unsafe_fraction = clampf(_shape_cast.get_closest_collision_unsafe_fraction(), 0.0, 1.0)

	return HitSweepResult.new(collisions, unsafe_fraction)


func _get_collisions_at_motion(
	motion: Vector2,
	excluded_hurtboxes: Array[Hurtbox]
) -> Array[BallHitCollision]:
	_shape_cast.clear_exceptions()

	for hurtbox in excluded_hurtboxes:
		if hurtbox != null and is_instance_valid(hurtbox):
			_shape_cast.add_exception(hurtbox)

	_shape_cast.target_position = motion
	_shape_cast.force_shapecast_update()

	var collision_by_hurtbox_id: Dictionary[int, BallHitCollision] = {}

	for collision_index in _shape_cast.get_collision_count():
		var hurtbox := _shape_cast.get_collider(collision_index) as Hurtbox
		if hurtbox == null or hurtbox.is_queued_for_deletion():
			continue

		var collision := BallHitCollision.new(hurtbox, _shape_cast.get_collision_point(collision_index))
		var hurtbox_id := hurtbox.get_instance_id()
		var current_collision: BallHitCollision = collision_by_hurtbox_id.get(hurtbox_id)

		if (
			current_collision == null
			or _is_collision_nearer(
				collision.position,
				current_collision.position,
				motion
			)
		):
			collision_by_hurtbox_id[hurtbox_id] = collision

	_shape_cast.clear_exceptions()

	var collisions: Array[BallHitCollision] = []
	collisions.assign(collision_by_hurtbox_id.values())
	return collisions


func _is_collision_nearer(
	candidate_position: Vector2,
	current_position: Vector2,
	motion: Vector2
) -> bool:
	var candidate_offset := candidate_position - global_position
	var current_offset := current_position - global_position

	if motion.is_zero_approx():
		return candidate_offset.length_squared() < current_offset.length_squared()

	var direction := motion.normalized()
	return candidate_offset.dot(direction) < current_offset.dot(direction)
