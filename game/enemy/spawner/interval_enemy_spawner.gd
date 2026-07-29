class_name IntervalEnemySpawner
extends EnemySpawner

enum SpawnMode {
	INSIDE_CIRCLE,
	AREA_PERIMETER,
}

@export_group("Spawn")
@export_range(0.01, 3.0, 0.01) var spawn_interval: float = 0.3
@export_range(0, 10000, 1) var max_enemy_count: int = 300
@export var spawn_mode: SpawnMode = SpawnMode.AREA_PERIMETER

@export_group("Circle Spawn")
@export var spawn_center: Vector2 = Vector2(-860.0, 0.0)
@export_range(0.0, 1000.0, 1.0) var spawn_radius: float = 100.0

@export_group("Perimeter Spawn")
@export var spawn_area_size: Vector2 = Vector2(1820.0, 1000.0)

@export_group("Destination")
@export var destination_position: Vector2 = Vector2.ZERO
@export var destination_target: Node2D

var _enemy_count: int = 0
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	super()

	_random.randomize()
	_spawn_loop()


func get_enemy_count() -> int:
	return _enemy_count


func _spawn_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(spawn_interval).timeout

		if not is_inside_tree():
			return

		if _enemy_count >= max_enemy_count:
			continue

		_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy := _create_enemy(_get_spawn_position())
	if enemy == null:
		return

	_enemy_count += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited, CONNECT_ONE_SHOT)

	if is_instance_valid(destination_target):
		enemy.set_destination_target(destination_target)
	else:
		enemy.set_destination(destination_position)

	_notify_enemy_spawned(enemy)


func _on_enemy_tree_exited() -> void:
	_enemy_count = maxi(_enemy_count - 1, 0)


func _get_spawn_position() -> Vector2:
	if spawn_mode == SpawnMode.INSIDE_CIRCLE:
		var angle := _random.randf_range(0.0, TAU)
		var distance := sqrt(_random.randf()) * spawn_radius

		return spawn_center + Vector2.from_angle(angle) * distance

	var area := _get_spawn_area()

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


func _get_spawn_area() -> Rect2:
	var viewport_rect := get_viewport().get_visible_rect()
	var screen_center := viewport_rect.get_center()
	var world_center := (get_viewport().get_canvas_transform().affine_inverse() * screen_center)
	var area_size := spawn_area_size.abs()

	return Rect2(world_center - area_size * 0.5, area_size)
