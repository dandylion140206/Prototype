class_name WanderingEnemySystem
extends Node2D

const PLACEMENT_ATTEMPTS_PER_ENEMY: int = 100

signal enemy_spawned(enemy: Enemy)
signal enemy_died(world_position: Vector2)
signal audio_requested(request: AudioRequest)

@export var enemy_scene: PackedScene

@export_group("Audio")
@export var enemy_death_audio_cue: AudioCue

@export_group("Population")
@export_range(1, 1000, 1) var enemy_count: int = 40
@export_range(0.0, 1000.0, 1.0) var minimum_spawn_distance: float = 50.0

@export_group("Wandering")
@export var wander_area: Rect2 = Rect2(-800.0, -650.0, 1600.0, 700.0)
@export_range(0.0, 500.0, 1.0) var target_reached_distance: float = 40.0
@export_range(0.1, 30.0, 0.1) var min_destination_duration: float = 4.0
@export_range(0.1, 30.0, 0.1) var max_destination_duration: float = 8.0

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _enemies: Dictionary[int, Enemy] = {}
var _destinations: Dictionary[int, Vector2] = {}
var _destination_time_left: Dictionary[int, float] = {}
var _pending_respawn_count: int = 0

@onready var _enemy_crowd_system: EnemyCrowdSystem = $EnemyCrowdSystem
@onready var _active_enemies: Node2D = $ActiveEnemies


func _ready() -> void:
	assert(enemy_scene != null, "enemy_scene must not be null.")
	assert(enemy_death_audio_cue != null, "enemy_death_audio_cue must not be null.")
	assert(wander_area.size.x > 0.0, "wander_area width must be greater than zero.")
	assert(wander_area.size.y > 0.0, "wander_area height must be greater than zero.")
	assert(
		min_destination_duration <= max_destination_duration,
		"min_destination_duration must not exceed max_destination_duration."
	)

	_random.randomize()
	_spawn_enemies.call_deferred()


func _physics_process(delta: float) -> void:
	var reached_distance_squared := target_reached_distance * target_reached_distance

	for enemy_id_value: Variant in _enemies.keys():
		var enemy_id := int(enemy_id_value)
		var enemy := _enemies[enemy_id]
		if not is_instance_valid(enemy):
			_remove_enemy(enemy_id)
			continue

		var destination := _destinations[enemy_id]
		var time_left := _destination_time_left[enemy_id] - delta
		if (
			enemy.global_position.distance_squared_to(destination)
			<= reached_distance_squared
			or time_left <= 0.0
		):
			_assign_destination(enemy, enemy_id)
			continue

		_destination_time_left[enemy_id] = time_left


func get_enemy_count() -> int:
	return _enemies.size()


func get_crowd_agent_count() -> int:
	return _enemy_crowd_system.get_agent_count()


func get_crowd_pair_count() -> int:
	return _enemy_crowd_system.get_crowd_pair_count()


func _spawn_enemies() -> void:
	var spawn_positions := PackedVector2Array()

	for _enemy_index in enemy_count:
		var spawn_position_value: Variant = _find_spawn_position(spawn_positions)
		if spawn_position_value == null:
			push_warning(
				"Enemy spawning stopped because the configured area could not fit every enemy."
			)
			return

		var spawn_position := spawn_position_value as Vector2
		spawn_positions.append(spawn_position)
		_spawn_enemy(spawn_position)


func _spawn_enemy(local_position: Vector2) -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("enemy_scene root must inherit Enemy.")
		return

	_active_enemies.add_child(enemy)
	enemy.global_position = to_global(local_position)
	enemy.reset_physics_interpolation()

	var enemy_id := enemy.get_instance_id()
	_enemies[enemy_id] = enemy
	_enemy_crowd_system.register(enemy.get_crowd_agent())
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy_id), CONNECT_ONE_SHOT)

	_assign_destination(enemy, enemy_id)
	enemy_spawned.emit(enemy)


func _find_spawn_position(spawn_positions: PackedVector2Array) -> Variant:
	var minimum_distance_squared := minimum_spawn_distance * minimum_spawn_distance

	for _attempt_index in PLACEMENT_ATTEMPTS_PER_ENEMY:
		var candidate := _get_random_local_position()
		if _is_separated_from_positions(
			candidate,
			spawn_positions,
			minimum_distance_squared
		):
			return candidate

	return null


func _is_separated_from_positions(
	candidate: Vector2,
	spawn_positions: PackedVector2Array,
	minimum_distance_squared: float
) -> bool:
	for spawn_position in spawn_positions:
		if candidate.distance_squared_to(spawn_position) < minimum_distance_squared:
			return false

	return true


func _assign_destination(enemy: Enemy, enemy_id: int) -> void:
	var destination := to_global(_get_random_local_position())

	_destinations[enemy_id] = destination
	_destination_time_left[enemy_id] = _random.randf_range(
		min_destination_duration,
		max_destination_duration
	)
	enemy.set_destination(destination)


func _get_random_local_position() -> Vector2:
	return Vector2(
		_random.randf_range(wander_area.position.x, wander_area.end.x),
		_random.randf_range(wander_area.position.y, wander_area.end.y)
	)


func _on_enemy_died(enemy: Enemy) -> void:
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
	_destinations.erase(enemy_id)
	_destination_time_left.erase(enemy_id)


func _spawn_replacement() -> void:
	var spawn_positions := PackedVector2Array()

	for enemy_value: Variant in _enemies.values():
		var enemy := enemy_value as Enemy
		if enemy != null and is_instance_valid(enemy):
			spawn_positions.append(to_local(enemy.global_position))

	var spawn_position_value: Variant = _find_spawn_position(spawn_positions)
	if spawn_position_value == null:
		push_warning("A replacement enemy could not be placed inside the wander area.")
		return

	_spawn_enemy(spawn_position_value as Vector2)
