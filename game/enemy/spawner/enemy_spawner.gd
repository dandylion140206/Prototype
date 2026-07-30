@abstract
class_name EnemySpawner
extends Node2D


signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene

var _spawn_parent: Node


func _ready() -> void:
	assert(enemy_scene != null, "enemy_scene must not be null.")


func set_spawn_parent(spawn_parent: Node) -> void:
	assert(spawn_parent != null, "spawn_parent must not be null.")

	_spawn_parent = spawn_parent


func _create_enemy(spawn_position: Vector2) -> Enemy:
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("enemy_scene root must inherit Enemy.")
		return null

	assert(_spawn_parent != null, "set_spawn_parent must be called before spawning enemies.")

	_spawn_parent.add_child(enemy)
	enemy.global_position = spawn_position

	# 物理補間の前フレーム位置を初期化し、原点からの補間を防ぐ。
	enemy.reset_physics_interpolation()

	return enemy


func _notify_enemy_spawned(enemy: Enemy) -> void:
	assert(enemy != null, "enemy must not be null.")

	enemy_spawned.emit(enemy)
