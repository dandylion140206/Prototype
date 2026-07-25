class_name EnemySpawner
extends Node2D

signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export_range(0.01, 60.0, 0.01) var spawn_interval: float = 0.5
@export_range(0.0, 10000.0, 1.0) var spawn_radius: float = 200.0
@export var destination: Vector2 = Vector2(100.0, 540.0)
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
	enemy.set_destination(destination)

	if destination_target != null and is_instance_valid(destination_target):
		enemy.set_destination_target(destination_target)

	enemy_spawned.emit(enemy)


func _get_spawn_position() -> Vector2:
	var angle := _random.randf_range(0.0, TAU)
	var distance := sqrt(_random.randf()) * spawn_radius
	var offset := Vector2.from_angle(angle) * distance

	return global_position + offset

