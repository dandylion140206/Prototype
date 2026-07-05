class_name TargetSpawner
extends Node2D

signal target_spawned(target: Target)

@export var target_scene: PackedScene
@export_range(1, 100, 1) var target_count: int = 30
@export_range(0.0, 10.0, 0.1) var respawn_delay: float = 0.0

@export var spawn_area: Rect2 = Rect2(Vector2(100.0, 100.0), Vector2(1720.0, 880.0))
@export_range(0.0, 1000.0, 10.0) var min_distance_from_targets: float = 120.0
@export_range(1, 100, 1) var max_spawn_attempts: int = 30

var targets: Array[Target] = []
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	assert(target_scene != null, "target_scene must not be null.")

	_random.randomize()
	spawn_initial_targets()


func spawn_initial_targets() -> void:
	for i in range(target_count):
		_spawn_target()


func _spawn_target() -> void:
	var target := target_scene.instantiate() as Target

	add_child(target)

	target.global_position = _find_spawn_position()
	target.health.died.connect(_on_target_died.bind(target))

	targets.append(target)
	target_spawned.emit(target)


func _on_target_died(target: Target) -> void:
	targets.erase(target)

	if respawn_delay <= 0.0:
		call_deferred("_spawn_target")
		return

	await get_tree().create_timer(respawn_delay).timeout
	_spawn_target()


func _find_spawn_position() -> Vector2:
	for i in range(max_spawn_attempts):
		var position := _get_random_position()

		if _is_valid_spawn_position(position):
			return position

	return _get_random_position()


func _get_random_position() -> Vector2:
	var x := _random.randf_range(spawn_area.position.x, spawn_area.end.x)
	var y := _random.randf_range(spawn_area.position.y, spawn_area.end.y)

	return Vector2(x, y)


func _is_valid_spawn_position(position: Vector2) -> bool:
	for target in targets:
		if target == null:
			continue

		if not is_instance_valid(target):
			continue

		if position.distance_to(target.global_position) < min_distance_from_targets:
			return false

	return true
