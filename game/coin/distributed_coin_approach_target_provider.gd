@tool
class_name DistributedCoinApproachTargetProvider
extends CoinApproachTargetProvider

const EDITOR_COLOR := Color(0.2, 0.8, 1.0, 0.16)
const EDITOR_SEGMENT_COUNT: int = 64

@export_group("Shape")
@export var size: Vector2 = Vector2(900.0, 240.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		queue_redraw()
@export_range(0.0, 1000.0, 1.0) var edge_margin: float = 24.0

@export_group("Distribution")
@export_range(1, 128, 1) var candidate_count: int = 20
@export_range(1.0, 1000.0, 1.0) var density_radius: float = 140.0
@export_range(0.0, 10.0, 0.01) var separation_weight: float = 4.0
@export_range(0.0, 10.0, 0.01) var density_weight: float = 2.0
@export_range(0.0, 10.0, 0.01) var edge_weight: float = 0.5
@export_range(0.0, 10.0, 0.01) var travel_weight: float = 0.75
@export_range(0.0, 10.0, 0.01) var randomness_weight: float = 0.25

var _raid_area: CoinRaidArea
var _active_enemies: Node
var _assignments: Dictionary[Enemy, Vector2] = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	draw_colored_polygon(_create_ellipse_points(size * 0.5), EDITOR_COLOR)


func setup(raid_area: CoinRaidArea, active_enemies: Node) -> void:
	assert(raid_area != null, "raid_area must not be null.")
	assert(active_enemies != null, "active_enemies must not be null.")

	_raid_area = raid_area
	_active_enemies = active_enemies


func assign_target(enemy: Enemy) -> Vector2:
	assert(enemy != null, "enemy must not be null.")
	assert(_raid_area != null, "setup must be called before assigning targets.")

	if _assignments.has(enemy):
		return _assignments[enemy]

	var target := _select_target(enemy)
	_assignments[enemy] = target
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)

	return target


func get_target_ratio(enemy: Enemy) -> float:
	assert(enemy != null, "enemy must not be null.")
	assert(_assignments.has(enemy), "assign_target must be called before getting its ratio.")

	var target := _assignments[enemy]
	var local_target := to_local(target)
	var horizontal_radius := _get_available_radius().x
	return clampf(inverse_lerp(-horizontal_radius, horizontal_radius, local_target.x), 0.0, 1.0)


func release_target(enemy: Enemy) -> void:
	if enemy == null:
		return

	_assignments.erase(enemy)


func get_assignment_count() -> int:
	return _assignments.size()


func _select_target(enemy: Enemy) -> Vector2:
	var best_target := global_position
	var best_score := -INF

	for _candidate_index in candidate_count:
		var candidate := to_global(_create_random_local_position())
		if not _raid_area.is_global_position_inside(candidate):
			continue

		var score := _score_candidate(candidate, enemy)
		if score <= best_score:
			continue

		best_score = score
		best_target = candidate

	return best_target


func _score_candidate(candidate: Vector2, enemy: Enemy) -> float:
	var maximum_distance := maxf(size.length(), 1.0)
	var separation_score := _get_minimum_assignment_distance(candidate) / maximum_distance
	var nearby_enemy_count := _count_nearby_enemies(candidate, enemy)
	var density_score := 1.0 / (1.0 + float(nearby_enemy_count))
	var local_candidate := to_local(candidate)
	var radius := _get_available_radius()
	var normalized_radius := Vector2(
		local_candidate.x / radius.x,
		local_candidate.y / radius.y
	).length()
	var edge_score := clampf(1.0 - normalized_radius, 0.0, 1.0)
	var travel_score := 1.0 - minf(
		enemy.global_position.distance_to(candidate) / maximum_distance,
		1.0
	)

	return (
		separation_score * separation_weight
		+ density_score * density_weight
		+ edge_score * edge_weight
		+ travel_score * travel_weight
		+ _random.randf() * randomness_weight
	)


func _get_minimum_assignment_distance(candidate: Vector2) -> float:
	if _assignments.is_empty():
		return size.length()

	var minimum_distance := INF
	for target_value: Variant in _assignments.values():
		var target := target_value as Vector2
		minimum_distance = minf(minimum_distance, candidate.distance_to(target))

	return minimum_distance


func _count_nearby_enemies(candidate: Vector2, ignored_enemy: Enemy) -> int:
	var nearby_enemy_count := 0
	var density_radius_squared := density_radius * density_radius

	for child in _active_enemies.get_children():
		var enemy := child as Enemy
		if enemy == null or enemy == ignored_enemy:
			continue

		if candidate.distance_squared_to(enemy.global_position) <= density_radius_squared:
			nearby_enemy_count += 1

	return nearby_enemy_count


func _create_random_local_position() -> Vector2:
	var radius := _get_available_radius()
	var angle := _random.randf_range(0.0, TAU)
	var distance_factor := sqrt(_random.randf())
	return Vector2(
		cos(angle) * radius.x * distance_factor,
		sin(angle) * radius.y * distance_factor
	)


func _get_available_radius() -> Vector2:
	return Vector2(
		maxf(size.x * 0.5 - edge_margin, 1.0),
		maxf(size.y * 0.5 - edge_margin, 1.0)
	)


func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	release_target(enemy)


func _create_ellipse_points(radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(EDITOR_SEGMENT_COUNT)

	for index in EDITOR_SEGMENT_COUNT:
		var angle := TAU * float(index) / float(EDITOR_SEGMENT_COUNT)
		points[index] = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)

	return points
