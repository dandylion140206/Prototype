class_name EnemySpawner
extends Node2D

signal enemy_spawned(enemy: Enemy)

enum SpawnMode {
	INSIDE_AREA,
	AREA_PERIMETER,
}

@export_group("Spawn")
@export var enemy_scene: PackedScene
@export_range(0.01, 5.0, 0.01) var spawn_interval: float = 0.5
@export var spawn_mode: SpawnMode = SpawnMode.AREA_PERIMETER
@export var spawn_area: Rect2 = Rect2(50.0, 50.0, 1820.0, 1000.0)

@export_group("Destination")
@export var destination_position: Vector2 = Vector2(960.0, 540.0)
@export var destination_target: Node2D

var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	assert(enemy_scene != null, "enemy_scene must not be null.")

	_random.randomize()
	_spawn_loop()


func _spawn_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(spawn_interval).timeout

		if not is_inside_tree():
			return

		_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("enemy_scene root must inherit Enemy.")
		return

	var spawn_parent := get_parent()
	assert(spawn_parent != null, "EnemySpawner must have a parent.")

	spawn_parent.add_child(enemy)
	enemy.global_position = _get_spawn_position()
	enemy.set_destination(destination_position)

	if destination_target != null and is_instance_valid(destination_target):
		enemy.set_destination_target(destination_target)

	enemy_spawned.emit(enemy)


func _get_spawn_position() -> Vector2:
	var area := spawn_area.abs()

	if spawn_mode == SpawnMode.INSIDE_AREA:
		return Vector2(
			_random.randf_range(area.position.x, area.end.x),
			_random.randf_range(area.position.y, area.end.y)
		)

	match _random.randi_range(0, 3):
		0:
			return Vector2(_random.randf_range(area.position.x, area.end.x), area.position.y)
		1:
			return Vector2(area.end.x, _random.randf_range(area.position.y, area.end.y))
		2:
			return Vector2(_random.randf_range(area.position.x, area.end.x), area.end.y)
		3:
			return Vector2(area.position.x, _random.randf_range(area.position.y, area.end.y))

	return area.get_center()
