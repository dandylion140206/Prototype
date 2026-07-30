@tool
class_name CoinRaidArea
extends Node2D

const EDITOR_COLOR := Color(1.0, 0.35, 0.2, 0.18)
const EDITOR_SEGMENT_COUNT: int = 64

@export var size: Vector2 = Vector2(980.0, 320.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	draw_colored_polygon(_create_ellipse_points(size * 0.5), EDITOR_COLOR)


func is_global_position_inside(world_position: Vector2) -> bool:
	var local_position := to_local(world_position)
	var radius := size * 0.5
	return (
		local_position.x * local_position.x / (radius.x * radius.x)
		+ local_position.y * local_position.y / (radius.y * radius.y)
		<= 1.0
	)


func _create_ellipse_points(radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(EDITOR_SEGMENT_COUNT)

	for index in EDITOR_SEGMENT_COUNT:
		var angle := TAU * float(index) / float(EDITOR_SEGMENT_COUNT)
		points[index] = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)

	return points
