class_name TargetSpawner
extends Node2D

signal target_spawned(target: Target)

@export var target_scene: PackedScene
@export_range(1, 100, 1) var target_count: int = 30
@export_range(1, 100, 1) var spawn_group_size_min: int = 3
@export_range(1, 100, 1) var spawn_group_size_max: int = 5
@export_range(0.0, 10.0, 0.05) var spawn_group_cooldown: float = 0.3
@export_range(0.0, 1000.0, 10.0) var spawn_margin: float = 100.0
@export_range(0.0, 1000.0, 5.0) var spawn_spread_radius: float = 50.0
@export_range(0.0, 0.99, 0.01) var top_bottom_center_exclusion_ratio: float = 0.4
@export_range(0.0, 100.0, 0.1) var spawn_weight_top: float = 1.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_right: float = 1.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_bottom: float = 1.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_left: float = 1.0
@export var goal_area_radius := Vector2(480.0, 270.0)
@export_range(1, 32, 1) var goal_proximity_candidate_count: int = 4

var targets: Array[Target] = []
var _random := RandomNumberGenerator.new()
var _spawn_loop_running := false


enum SpawnSide {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
}


func _ready() -> void:
	_validate_configuration()

	_random.randomize()
	_request_spawn()


func _request_spawn() -> void:
	if _spawn_loop_running:
		return

	_spawn_loop_running = true

	while _can_spawn_group():
		_spawn_group()

		if spawn_group_cooldown > 0.0:
			await get_tree().create_timer(spawn_group_cooldown).timeout

	_spawn_loop_running = false


func _can_spawn_group() -> bool:
	return target_count - targets.size() >= spawn_group_size_min


func _spawn_group() -> void:
	var viewport_size := get_viewport_rect().size
	var group_size := _get_spawn_group_size()
	var spawn_side := _get_spawn_side()
	var base_position := _get_group_base_position(spawn_side, viewport_size)

	for i in range(group_size):
		_spawn_target(base_position, viewport_size)


func _get_spawn_group_size() -> int:
	var free_slots := target_count - targets.size()
	var maximum_group_size: int = min(spawn_group_size_max, free_slots)

	return _random.randi_range(spawn_group_size_min, maximum_group_size)


func _spawn_target(base_position: Vector2, viewport_size: Vector2) -> void:
	var target := target_scene.instantiate() as Target
	var spawn_position := _get_actual_spawn_position(base_position)
	var goal_position := _get_goal_position(spawn_position, viewport_size)

	add_child(target)

	target.initialize_movement(
		spawn_position,
		goal_position,
		viewport_size,
		spawn_margin
	)
	target.died.connect(_on_target_finished.bind(target))
	target.exited.connect(_on_target_finished.bind(target))

	targets.append(target)
	target_spawned.emit(target)


func _on_target_finished(target: Target) -> void:
	targets.erase(target)
	_request_spawn()


func _get_group_base_position(
	spawn_side: SpawnSide,
	viewport_size: Vector2
) -> Vector2:
	match spawn_side:
		SpawnSide.TOP:
			return Vector2(_get_top_bottom_spawn_x(viewport_size.x), -spawn_margin)
		SpawnSide.RIGHT:
			return Vector2(viewport_size.x + spawn_margin, _random.randf_range(0.0, viewport_size.y))
		SpawnSide.BOTTOM:
			return Vector2(_get_top_bottom_spawn_x(viewport_size.x), viewport_size.y + spawn_margin)
		SpawnSide.LEFT:
			return Vector2(-spawn_margin, _random.randf_range(0.0, viewport_size.y))

	return Vector2.ZERO


func _get_top_bottom_spawn_x(viewport_width: float) -> float:
	var allowed_segment_width := viewport_width * (
		1.0 - top_bottom_center_exclusion_ratio
	) * 0.5

	if _random.randf() < 0.5:
		return _random.randf_range(0.0, allowed_segment_width)

	return _random.randf_range(
		viewport_width - allowed_segment_width,
		viewport_width
	)


func _get_actual_spawn_position(base_position: Vector2) -> Vector2:
	var angle := _random.randf_range(0.0, TAU)
	var radius := sqrt(_random.randf()) * spawn_spread_radius
	var spawn_offset := Vector2(cos(angle), sin(angle)) * radius

	return base_position + spawn_offset


func _get_goal_position(
	spawn_position: Vector2,
	viewport_size: Vector2
) -> Vector2:
	var closest_goal_position := _get_goal_candidate(viewport_size)
	var closest_distance_squared := spawn_position.distance_squared_to(
		closest_goal_position
	)

	for i in range(goal_proximity_candidate_count - 1):
		var candidate := _get_goal_candidate(viewport_size)
		var candidate_distance_squared := spawn_position.distance_squared_to(candidate)

		if candidate_distance_squared < closest_distance_squared:
			closest_goal_position = candidate
			closest_distance_squared = candidate_distance_squared

	return closest_goal_position


func _get_goal_candidate(viewport_size: Vector2) -> Vector2:
	var angle := _random.randf_range(0.0, TAU)
	var radius_scale := sqrt(_random.randf())
	var ellipse_offset := Vector2(cos(angle), sin(angle)) * goal_area_radius * radius_scale

	return viewport_size * 0.5 + ellipse_offset


func _get_spawn_side() -> SpawnSide:
	var selected_weight := _random.randf_range(0.0, _get_total_spawn_weight())

	if selected_weight < spawn_weight_top:
		return SpawnSide.TOP

	selected_weight -= spawn_weight_top
	if selected_weight < spawn_weight_right:
		return SpawnSide.RIGHT

	selected_weight -= spawn_weight_right
	if selected_weight < spawn_weight_bottom:
		return SpawnSide.BOTTOM

	return SpawnSide.LEFT


func _get_total_spawn_weight() -> float:
	return (
		spawn_weight_top
		+ spawn_weight_right
		+ spawn_weight_bottom
		+ spawn_weight_left
	)


func _validate_configuration() -> void:
	assert(target_scene != null, "target_scene must not be null.")
	assert(_get_total_spawn_weight() > 0.0, "At least one spawn weight must be greater than zero.")
	assert(spawn_group_size_min >= 1, "spawn_group_size_min must be at least one.")
	assert(
		spawn_group_size_max >= spawn_group_size_min,
		"spawn_group_size_max must be at least spawn_group_size_min."
	)
	assert(target_count >= spawn_group_size_min, "target_count must fit one spawn group.")
	assert(goal_proximity_candidate_count >= 1, "goal_proximity_candidate_count must be at least one.")
	assert(
		top_bottom_center_exclusion_ratio >= 0.0
		and top_bottom_center_exclusion_ratio < 1.0,
		"top_bottom_center_exclusion_ratio must be from 0.0 up to, but not including, 1.0."
	)
	assert(spawn_spread_radius >= 0.0, "spawn_spread_radius must not be negative.")
	assert(spawn_group_cooldown >= 0.0, "spawn_group_cooldown must not be negative.")
