@tool
class_name LineSegment2D
extends Node2D

## Local -Y represents the outward side of the line.

@export_range(0.0, 10000.0, 1.0, "or_greater") var length: float = 1600.0:
	set(value):
		length = maxf(value, 0.0)
		queue_redraw()
@export var editor_color: Color = Color(0.2, 0.8, 1.0, 0.9):
	set(value):
		editor_color = value
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var half_length := length * 0.5
	draw_line(Vector2(-half_length, 0.0), Vector2(half_length, 0.0), editor_color, 3.0)
	draw_line(Vector2.ZERO, Vector2(0.0, -24.0), editor_color, 3.0)
	draw_line(Vector2(0.0, -24.0), Vector2(-6.0, -16.0), editor_color, 3.0)
	draw_line(Vector2(0.0, -24.0), Vector2(6.0, -16.0), editor_color, 3.0)


func get_random_local_point(random: RandomNumberGenerator) -> Vector2:
	assert(random != null, "random must not be null.")

	var half_length := length * 0.5
	return Vector2(random.randf_range(-half_length, half_length), 0.0)


func get_closest_global_point(global_point: Vector2, outward_offset: float = 0.0) -> Vector2:
	var local_point := to_local(global_point)
	var half_length := length * 0.5
	local_point.x = clampf(local_point.x, -half_length, half_length)
	local_point.y = -outward_offset

	return to_global(local_point)


func has_global_point_crossed_outward(global_point: Vector2) -> bool:
	return to_local(global_point).y <= 0.0
