class_name WaveEnemySpawner
extends EnemySpawner

const PLACEMENT_ATTEMPTS_PER_ENEMY: int = 100

@export_group("Wave")
@export_range(1, 10000, 1) var min_wave_size: int = 5
@export_range(1, 10000, 1) var max_wave_size: int = 10
@export_range(1, 10000, 1) var max_enemy_count: int = 100

@export_group("Timing")
@export_range(0.0, 5.0, 0.01) var min_wave_interval: float = 0.3
@export_range(0.0, 5.0, 0.01) var max_wave_interval: float = 0.7
@export_range(0.0, 1.0, 0.01) var enemy_spawn_interval: float = 0.1

@export_group("Placement")
@export_range(0.0, 5000.0, 1.0) var cluster_radius: float = 100.0
@export_range(0.0, 1000.0, 1.0) var minimum_spawn_distance: float = 20.0

var _spawn_line: LineSegment2D
var _enemies: Dictionary[int, Enemy] = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _has_started: bool = false


func _ready() -> void:
	super()

	assert(min_wave_size <= max_wave_size, "min_wave_size must not exceed max_wave_size.")
	assert(min_wave_interval <= max_wave_interval, "min_wave_interval must not exceed max_wave_interval.")
	_random.randomize()


func setup(spawn_line: LineSegment2D) -> void:
	assert(spawn_line != null, "spawn_line must not be null.")
	assert(not _has_started, "WaveEnemySpawner.setup must only be called once.")

	_spawn_line = spawn_line
	_has_started = true
	_spawn_loop()


func get_enemy_count() -> int:
	return _enemies.size()


func _spawn_loop() -> void:
	while is_inside_tree():
		await _spawn_wave()
		if not is_inside_tree():
			return

		var wave_interval := _random.randf_range(min_wave_interval, max_wave_interval)
		await get_tree().create_timer(wave_interval).timeout


func _spawn_wave() -> void:
	var wave_size := _random.randi_range(min_wave_size, max_wave_size)
	if _enemies.size() + wave_size > max_enemy_count:
		return

	var spawn_positions := _create_wave_spawn_positions(wave_size)
	if spawn_positions.size() != wave_size:
		return

	for index in spawn_positions.size():
		if not is_inside_tree():
			return

		var spawn_position := _spawn_line.to_global(spawn_positions[index])
		if not _spawn_enemy(spawn_position):
			return

		if index >= spawn_positions.size() - 1 or enemy_spawn_interval <= 0.0:
			continue

		await get_tree().create_timer(enemy_spawn_interval).timeout


func _spawn_enemy(spawn_position: Vector2) -> bool:
	var enemy := _create_enemy(spawn_position)
	if enemy == null:
		return false

	var enemy_id := enemy.get_instance_id()
	_enemies[enemy_id] = enemy
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy_id), CONNECT_ONE_SHOT)
	_notify_enemy_spawned(enemy)

	return true


func _on_enemy_tree_exited(enemy_id: int) -> void:
	_enemies.erase(enemy_id)


func _create_wave_spawn_positions(wave_size: int) -> PackedVector2Array:
	var spawn_positions := PackedVector2Array()
	var cluster_center := _spawn_line.get_random_local_point(_random)

	for _enemy_index in wave_size:
		var spawn_position: Variant = _find_spawn_position(cluster_center, spawn_positions)
		if spawn_position == null:
			push_warning("Wave spawn was cancelled because the configured placement could not fit every enemy.")
			return PackedVector2Array()

		spawn_positions.append(spawn_position as Vector2)

	return spawn_positions


func _find_spawn_position(
	cluster_center: Vector2,
	spawn_positions: PackedVector2Array
) -> Variant:
	var minimum_distance_squared := minimum_spawn_distance * minimum_spawn_distance

	for _attempt_index in PLACEMENT_ATTEMPTS_PER_ENEMY:
		var angle := _random.randf_range(0.0, TAU)
		var distance := sqrt(_random.randf()) * cluster_radius
		var candidate := cluster_center + Vector2.from_angle(angle) * distance
		if not _is_inside_viewport(candidate):
			continue

		if _is_separated_from_positions(candidate, spawn_positions, minimum_distance_squared):
			return candidate

	return null


func _is_inside_viewport(local_position: Vector2) -> bool:
	var global_position := _spawn_line.to_global(local_position)
	var screen_position := get_viewport().get_canvas_transform() * global_position

	return get_viewport().get_visible_rect().has_point(screen_position)


func _is_separated_from_positions(
	candidate: Vector2,
	spawn_positions: PackedVector2Array,
	minimum_distance_squared: float
) -> bool:
	for spawn_position in spawn_positions:
		if candidate.distance_squared_to(spawn_position) < minimum_distance_squared:
			return false

	return true
