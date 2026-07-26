@abstract
class_name EnemySpawner
extends Node2D


signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene


func _ready() -> void:
	assert(enemy_scene != null, "enemy_scene must not be null.")


func _create_enemy() -> Enemy:
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("enemy_scene root must inherit Enemy.")
		return null

	var spawn_parent := get_parent()
	assert(
		spawn_parent != null,
		"EnemySpawner must have a parent."
	)

	spawn_parent.add_child(enemy)
	return enemy


func _notify_enemy_spawned(enemy: Enemy) -> void:
	assert(enemy != null, "enemy must not be null.")

	enemy_spawned.emit(enemy)
