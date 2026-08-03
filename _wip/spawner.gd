class_name Spawner
extends Node

## Enemy を指定数まで生成し、消滅を検知して補充する。
## NOTE: 生成した Enemy は自身の子として保持するため、解放するとまとめて消滅する。

signal enemy_spawned(enemy: SoftEnemy)

@export var enemy_scene: PackedScene = null
@export_range(1, 200, 1) var max_enemy_count: int = 5

## 出現位置と放浪範囲。グローバル座標で指定する。
@export var wander_area: Rect2 = Rect2(-128.0, -128.0, 256.0, 256.0)

@export var chase_target: Node2D = null
@export var enemy_movement_mode: SoftEnemy.MovementMode = SoftEnemy.MovementMode.WANDER
@export_range(0.0, 10.0, 0.1) var min_respawn_delay: float = 1.0
@export_range(0.0, 10.0, 0.1) var max_respawn_delay: float = 3.0

var _enemies: Array[SoftEnemy] = []


func _ready() -> void:
	print("spawner ready: ", enemy_scene)

	assert(enemy_scene != null, "enemy_scene を設定してください。")
	assert(wander_area.has_area(), "wander_area に面積のある Rect2 を設定してください。")
	assert(min_respawn_delay <= max_respawn_delay, "min_respawn_delay は max_respawn_delay 以下にしてください。")

	for i in max_enemy_count:
		_spawn_enemy()


func get_alive_count() -> int:
	return _enemies.size()


func _on_enemy_tree_exited(enemy: SoftEnemy) -> void:
	_enemies.erase(enemy)

	# NOTE: 自身が解放される際も呼ばれるため、SceneTree から外れている場合は補充しない。
	if not is_inside_tree():
		return

	_schedule_spawn()


func _schedule_spawn() -> void:
	var delay := randf_range(min_respawn_delay, max_respawn_delay)
	if delay <= 0.0:
		_spawn_enemy()
		return

	get_tree().create_timer(delay).timeout.connect(_spawn_enemy)


func _spawn_enemy() -> void:
	if _enemies.size() >= max_enemy_count:
		return

	var enemy := enemy_scene.instantiate() as SoftEnemy
	if enemy == null:
		push_error("enemy_scene には Enemy を Root に持つ Scene を設定してください。")
		return

	enemy.wander_area = wander_area
	enemy.chase_target = chase_target
	enemy.initial_movement_mode = enemy_movement_mode

	add_child(enemy)
	enemy.global_position = _get_random_position_in_area()
	_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))

	enemy_spawned.emit(enemy)


func _get_random_position_in_area() -> Vector2:
	var x := randf_range(wander_area.position.x, wander_area.end.x)
	var y := randf_range(wander_area.position.y, wander_area.end.y)
	return Vector2(x, y)
