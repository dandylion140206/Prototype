class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-800.0, -450.0, 1600.0, 900.0)
@export_range(0.0, 1000.0, 1.0, "or_greater") var minimum_spawn_distance: float = 50.0
@export_range(1, 1000, 1, "or_greater") var placement_attempts_per_enemy: int = 100

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	_validate()


func spawn(parent: Node, existing_world_positions: PackedVector2Array) -> Enemy:
	assert(enemy_scene != null, "enemy_scene must not be null.")
	assert(parent != null, "parent must not be null.")
	_validate()

	var spawn_position_value: Variant = find_spawn_position(existing_world_positions)
	if spawn_position_value == null:
		return null

	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("enemy_scene root must inherit Enemy.")
		return null

	parent.add_child(enemy)
	enemy.global_position = spawn_position_value as Vector2
	return enemy


func find_spawn_position(existing_world_positions: PackedVector2Array) -> Variant:
	var minimum_distance_squared := minimum_spawn_distance * minimum_spawn_distance
	for _attempt_index in placement_attempts_per_enemy:
		var candidate := to_global(_get_random_local_position())
		if _is_separated_from_positions(
			candidate,
			existing_world_positions,
			minimum_distance_squared
		):
			return candidate

	return null


func _get_random_local_position() -> Vector2:
	return Vector2(
		_random.randf_range(spawn_area.position.x, spawn_area.end.x),
		_random.randf_range(spawn_area.position.y, spawn_area.end.y)
	)


func _is_separated_from_positions(
	candidate: Vector2,
	existing_world_positions: PackedVector2Array,
	minimum_distance_squared: float
) -> bool:
	for position in existing_world_positions:
		if candidate.distance_squared_to(position) < minimum_distance_squared:
			return false

	return true


func _validate() -> void:
	assert(spawn_area.size.x > 0.0, "spawn_area width must be greater than zero.")
	assert(spawn_area.size.y > 0.0, "spawn_area height must be greater than zero.")
	assert(
		minimum_spawn_distance >= 0.0,
		"minimum_spawn_distance must not be negative."
	)
	assert(placement_attempts_per_enemy >= 1, "placement_attempts_per_enemy must be positive.")
