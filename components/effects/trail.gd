class_name Trail
extends Line2D

@export var target: Node2D
@export_range(1, 500, 1) var max_points: int = 200
@export_range(0.0, 32.0, 0.1) var min_distance: float = 4.0
@export_range(0.0, 1.0, 0.01) var point_lifetime: float = 0.3

var _point_ages: Array[float] = []


func _ready() -> void:
	clear_points()
	_point_ages.clear()


func _process(delta: float) -> void:
	_update_point_ages(delta)

	if target == null:
		return

	var local_point_position := to_local(target.global_position)
	var point_count := get_point_count()

	if point_count > 0:
		var last_point_position := get_point_position(point_count - 1)

		if local_point_position.distance_to(last_point_position) < min_distance:
			return

	add_point(local_point_position)
	_point_ages.append(0.0)

	while get_point_count() > max_points:
		_remove_oldest_point()


func reset_trail() -> void:
	clear_points()
	_point_ages.clear()


func _update_point_ages(delta: float) -> void:
	for i in range(_point_ages.size()):
		_point_ages[i] += delta

	while _point_ages.size() > 0 and _point_ages[0] >= point_lifetime:
		_remove_oldest_point()


func _remove_oldest_point() -> void:
	assert(get_point_count() > 0, "Cannot remove point because Trail has no points.")
	assert(_point_ages.size() > 0, "Cannot remove point age because Trail has no point ages.")

	remove_point(0)
	_point_ages.remove_at(0)
