class_name FixedCountEnemySpawner
extends EnemySpawner

@export_range(0, 10000, 1) var spawn_count: int = 50:
	set(value):
		spawn_count = maxi(value, 0)
		_request_reconcile()

@export_range(1, 100, 1) var max_spawns_per_frame: int = 20:
	set(value):
		max_spawns_per_frame = maxi(value, 1)
		_request_reconcile()
@export_range(0.0, 500.0, 1.0) var screen_margin: float = 50.0

var _enemies: Dictionary[int, Enemy] = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	super()

	_random.randomize()
	_request_reconcile()


func _process(_delta: float) -> void:
	_reconcile_enemy_count()


func get_enemy_count() -> int:
	return _enemies.size()


func set_spawn_count(value: int) -> void:
	spawn_count = value


func _request_reconcile() -> void:
	if not is_inside_tree():
		return

	set_process(true)


func _reconcile_enemy_count() -> void:
	if not is_inside_tree() or _enemies.size() >= spawn_count:
		set_process(false)
		return

	for _spawn_index in max_spawns_per_frame:
		if not _spawn_enemy():
			set_process(false)
			return

		if _enemies.size() >= spawn_count:
			set_process(false)
			return


func _spawn_enemy() -> bool:
	var enemy := _create_enemy(_get_random_spawn_position())
	if enemy == null:
		return false

	var enemy_id := enemy.get_instance_id()
	_enemies[enemy_id] = enemy

	enemy.died.connect(_on_enemy_removed.bind(enemy_id), CONNECT_ONE_SHOT)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy_id), CONNECT_ONE_SHOT)

	_notify_enemy_spawned(enemy)
	return true


func _on_enemy_removed(enemy_id: int) -> void:
	if not _enemies.has(enemy_id):
		return

	_enemies.erase(enemy_id)
	_request_reconcile()


func _get_random_spawn_position() -> Vector2:
	var viewport_rect := get_viewport().get_visible_rect()
	var max_margin := minf(viewport_rect.size.x, viewport_rect.size.y) * 0.5
	var available_margin := minf(screen_margin, max_margin)

	var screen_position := Vector2(
		_random.randf_range(
			viewport_rect.position.x + available_margin,
			viewport_rect.end.x - available_margin
		),
		_random.randf_range(
			viewport_rect.position.y + available_margin,
			viewport_rect.end.y - available_margin
		)
	)

	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
