@tool
class_name BallVisual
extends Node2D

const GRADIENT_STEP_COUNT: int = 64

@export_range(1.0, 500.0, 1.0) var radius: float = 28.0:
	set(value):
		radius = value
		queue_redraw()

@export var center_color: Color = Color.WHITE:
	set(value):
		center_color = value
		queue_redraw()

@export var outer_color: Color = Color.WHITE:
	set(value):
		outer_color = value
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var gradient_position: float = 0.5:
	set(value):
		gradient_position = value
		queue_redraw()

@export_range(0.01, 1.0, 0.01) var gradient_width: float = 1.0:
	set(value):
		gradient_width = value
		queue_redraw()


func _draw() -> void:
	var gradient_start := clampf(
		gradient_position - gradient_width * 0.5,
		0.0,
		1.0
	)
	var gradient_end := clampf(
		gradient_position + gradient_width * 0.5,
		0.0,
		1.0
	)

	draw_circle(Vector2.ZERO, radius, outer_color, true, -1.0, true)

	for step in range(GRADIENT_STEP_COUNT - 1, 0, -1):
		var radius_ratio := float(step) / float(GRADIENT_STEP_COUNT)
		var color_ratio := smoothstep(
			gradient_start,
			gradient_end,
			radius_ratio
		)
		var color := center_color.lerp(outer_color, color_ratio)
		draw_circle(Vector2.ZERO, radius * radius_ratio, color)
