class_name FixedCountEnemySpawner
extends EnemySpawner

@export_range(0, 10000, 1) var spawn_count: int = 20:
	set(value):
		spawn_count = maxi(value, 0)

		if is_inside_tree():
			_reconcile_enemy_count.call_deferred()

@export_range(0.0, 500.0, 1.0) var screen_margin: float = 50.0

var _enemies: Dictionary[int, Enemy] = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	super()

	_random.randomize()

	# Mainがenemy_spawnedへ接続した後に初期スポーンする。
	_reconcile_enemy_count.call_deferred()


func get_enemy_count() -> int:
	return _enemies.size()


func set_spawn_count(value: int) -> void:
	spawn_count = value


func _reconcile_enemy_count() -> void:
	if not is_inside_tree():
		return

	while _enemies.size() < spawn_count:
		if not _spawn_enemy():
			return


func _spawn_enemy() -> bool:
	var enemy := _create_enemy()
	if enemy == null:
		return false

	enemy.global_position = _get_random_spawn_position()

	var enemy_id := enemy.get_instance_id()
	_enemies[enemy_id] = enemy

	enemy.died.connect(
		_on_enemy_removed.bind(enemy_id),
		CONNECT_ONE_SHOT
	)
	enemy.tree_exited.connect(
		_on_enemy_removed.bind(enemy_id),
		CONNECT_ONE_SHOT
	)

	_notify_enemy_spawned(enemy)
	return true


func _on_enemy_removed(enemy_id: int) -> void:
	if not _enemies.has(enemy_id):
		return

	_enemies.erase(enemy_id)

	if is_inside_tree():
		_reconcile_enemy_count()


func _get_random_spawn_position() -> Vector2:
	var viewport_rect := get_viewport().get_visible_rect()
	var max_margin := (
		minf(viewport_rect.size.x, viewport_rect.size.y)
		* 0.5
	)
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

	return (
		get_viewport().get_canvas_transform().affine_inverse()
		* screen_position
	)
