class_name BenchmarkSpawner
extends Node2D

@export var enemy_scene: PackedScene
@export_range(0.0, 10000.0, 1.0) var spawn_radius: float = 600.0
@export var destination: Vector2 = Vector2(100.0, 540.0)
@export var random_seed: int = 20260725

var _enemies: Array[Enemy] = []
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	assert(enemy_scene != null, "enemy_scene must not be null.")


func spawn(count: int, parent: Node) -> void:
	clear()
	_random.seed = random_seed

	for _index in count:
		var enemy := enemy_scene.instantiate() as Enemy
		if enemy == null:
			push_error("enemy_scene root must inherit Enemy.")
			return

		parent.add_child(enemy)
		enemy.global_position = _get_spawn_position()
		enemy.set_destination(destination)
		_enemies.append(enemy)


func clear() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	_enemies.clear()


func get_spawned_count() -> int:
	return _enemies.size()


func _get_spawn_position() -> Vector2:
	var angle := _random.randf_range(0.0, TAU)
	var distance := sqrt(_random.randf()) * spawn_radius

	return global_position + Vector2.from_angle(angle) * distance
