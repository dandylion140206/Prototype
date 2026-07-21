class_name TargetSpawner
extends Node2D

signal target_spawned(target: Target)

@export var target_scene: PackedScene
@export_range(1, 100, 1) var target_count: int = 30
@export_range(0.0, 10.0, 0.1) var respawn_delay: float = 0.0
@export_range(0.0, 1000.0, 10.0) var spawn_margin: float = 100.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_top: float = 1.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_right: float = 1.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_bottom: float = 1.0
@export_range(0.0, 100.0, 0.1) var spawn_weight_left: float = 1.0
@export var goal_area_radius := Vector2(480.0, 270.0)

var targets: Array[Target] = []
var _random := RandomNumberGenerator.new()


enum SpawnSide {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
}


func _ready() -> void:
	assert(target_scene != null, "target_scene must not be null.")
	assert(_get_total_spawn_weight() > 0.0, "At least one spawn weight must be greater than zero.")

	_random.randomize()
	spawn_initial_targets()


func spawn_initial_targets() -> void:
	for i in range(target_count):
		_spawn_target()


func _spawn_target() -> void:
	if targets.size() >= target_count:
		return

	var target := target_scene.instantiate() as Target
	var viewport_size := get_viewport_rect().size
	var spawn_position := _get_spawn_position(viewport_size)
	var goal_position := _get_goal_position(viewport_size)

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

	if respawn_delay <= 0.0:
		call_deferred("_spawn_target")
		return

	await get_tree().create_timer(respawn_delay).timeout
	_spawn_target()


func _get_spawn_position(viewport_size: Vector2) -> Vector2:
	match _get_spawn_side():
		SpawnSide.TOP:
			return Vector2(_random.randf_range(0.0, viewport_size.x), -spawn_margin)
		SpawnSide.RIGHT:
			return Vector2(viewport_size.x + spawn_margin, _random.randf_range(0.0, viewport_size.y))
		SpawnSide.BOTTOM:
			return Vector2(_random.randf_range(0.0, viewport_size.x), viewport_size.y + spawn_margin)
		SpawnSide.LEFT:
			return Vector2(-spawn_margin, _random.randf_range(0.0, viewport_size.y))

	return Vector2.ZERO


func _get_goal_position(viewport_size: Vector2) -> Vector2:
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
