class_name HealthBar
extends Node2D

@export var size: Vector2 = Vector2(56.0, 6.0)

@export var background_color: Color = Color(0.0, 0.0, 0.0, 0.8)
@export var fill_color: Color = Color(0.2, 1.0, 0.3, 1.0)
@export var border_color: Color = Color.WHITE

var _health_ratio: float = 1.0


func _ready() -> void:
	visible = false


func update_health(current_health: float, max_health: float) -> void:
	if max_health <= 0.0:
		_health_ratio = 0.0
	else:
		_health_ratio = clampf(current_health / max_health, 0.0, 1.0)

	visible = _health_ratio < 1.0

	queue_redraw()


func hide_immediately() -> void:
	visible = false


func _draw() -> void:
	var top_left := -size * 0.5
	var background_rect := Rect2(top_left, size)

	draw_rect(background_rect, background_color, true)

	var fill_size := Vector2(size.x * _health_ratio, size.y)
	var fill_rect := Rect2(top_left, fill_size)

	draw_rect(fill_rect, fill_color, true)
	draw_rect(background_rect, border_color, false, 1.0)
