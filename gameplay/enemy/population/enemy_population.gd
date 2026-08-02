class_name EnemyPopulation
extends Node2D

signal enemy_spawned(enemy: Enemy)
signal enemy_died(world_position: Vector2)
signal audio_requested(request: AudioRequest)

@export_group("Audio")
@export var enemy_death_audio_cue: AudioCue

@export_group("Population")
@export_range(1, 1000, 1) var enemy_count: int = 40

@export_group("Wandering")
@export var wander_area: Rect2 = Rect2(-800.0, -650.0, 1600.0, 700.0)
@export_range(0.0, 500.0, 1.0, "or_greater") var wander_arrival_distance: float = 40.0
@export_range(0.001, 30.0, 0.1, "or_greater") var min_destination_duration: float = 4.0
@export_range(0.001, 30.0, 0.1, "or_greater") var max_destination_duration: float = 8.0

var _enemies: Dictionary[int, Enemy] = {}
var _pending_respawn_count: int = 0

@onready var _spawner: EnemySpawner = $EnemySpawner
@onready var _motion_system: EnemyMotionSystem = $EnemyMotionSystem
@onready var _crowd_system: EnemyCrowdSystem = $EnemyCrowdSystem
@onready var _active_enemies: Node2D = $ActiveEnemies


func _ready() -> void:
	assert(enemy_death_audio_cue != null, "enemy_death_audio_cue must not be null.")
	assert(enemy_count >= 1, "enemy_count must be positive.")
	assert(wander_area.size.x > 0.0, "wander_area width must be greater than zero.")
	assert(wander_area.size.y > 0.0, "wander_area height must be greater than zero.")
	assert(wander_arrival_distance >= 0.0, "wander_arrival_distance must not be negative.")
	assert(
		min_destination_duration > 0.0,
		"min_destination_duration must be greater than zero."
	)
	assert(
		max_destination_duration > 0.0,
		"max_destination_duration must be greater than zero."
	)
	assert(
		min_destination_duration <= max_destination_duration,
		"min_destination_duration must not exceed max_destination_duration."
	)

	_motion_system.setup(_crowd_system)
	_spawn_initial_enemies.call_deferred()


func get_enemy_count() -> int:
	return _enemies.size()


func get_crowd_agent_count() -> int:
	return _crowd_system.get_agent_count()


func get_crowd_pair_count() -> int:
	return _crowd_system.get_crowd_pair_count()


func _spawn_initial_enemies() -> void:
	var existing_positions := PackedVector2Array()
	for _enemy_index in enemy_count:
		var enemy := _spawner.spawn(_active_enemies, existing_positions)
		if enemy == null:
			push_warning(
				"Enemy spawning stopped because the configured area could not fit every enemy."
			)
			return

		existing_positions.append(enemy.global_position)
		_register_enemy(enemy)


func _register_enemy(enemy: Enemy) -> void:
	assert(enemy != null, "enemy must not be null.")

	enemy.reset_physics_interpolation()
	_enemies[enemy.get_instance_id()] = enemy
	enemy.start_wandering(
		_get_world_wander_area(),
		wander_arrival_distance,
		min_destination_duration,
		max_destination_duration
	)
	_motion_system.register(enemy.get_motor())
	_crowd_system.register(enemy.get_crowd_agent())
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.tree_exited.connect(
		_on_enemy_tree_exited.bind(enemy.get_instance_id()),
		CONNECT_ONE_SHOT
	)
	enemy_spawned.emit(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	_motion_system.unregister(enemy.get_motor())
	_crowd_system.unregister(enemy.get_crowd_agent())

	_pending_respawn_count += 1
	var death_position := enemy.global_position
	var audio_request := AudioRequest.new(
		enemy_death_audio_cue,
		death_position,
		enemy.get_instance_id()
	)
	audio_requested.emit(audio_request)
	enemy_died.emit(death_position)


func _on_enemy_tree_exited(enemy_id: int) -> void:
	_remove_enemy(enemy_id)
	if _pending_respawn_count <= 0 or not is_inside_tree():
		return

	_pending_respawn_count -= 1
	_spawn_replacement()


func _remove_enemy(enemy_id: int) -> void:
	_enemies.erase(enemy_id)


func _spawn_replacement() -> void:
	var existing_positions := PackedVector2Array()
	for enemy_value: Variant in _enemies.values():
		var enemy := enemy_value as Enemy
		if enemy != null and is_instance_valid(enemy):
			existing_positions.append(enemy.global_position)

	var enemy := _spawner.spawn(_active_enemies, existing_positions)
	if enemy == null:
		push_warning("A replacement enemy could not be placed inside the spawn area.")
		return

	_register_enemy(enemy)


func _get_world_wander_area() -> Rect2:
	return Rect2(to_global(wander_area.position), wander_area.size)
