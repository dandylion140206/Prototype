@tool
class_name CircleVisual
extends Node2D

@export_range(0.0, 100.0, 0.1) var radius: float = 20.0:
	set(value):
		radius = maxf(value, 0.0)
		queue_redraw()

@export var aspect_ratio: Vector2 = Vector2.ONE:
	set(value):
		aspect_ratio = Vector2(
			maxf(value.x, 0.0),
			maxf(value.y, 0.0)
		)
		queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, aspect_ratio)
	draw_circle(Vector2.ZERO, radius, color)
