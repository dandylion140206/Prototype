class_name RadialAttackVisual
extends Node2D

@export var fill_color: Color = Color(0.35, 0.8, 1.0, 0.18)
@export var outline_color: Color = Color(0.65, 0.95, 1.0, 0.9)
@export_range(0.1, 20.0, 0.1) var outline_width: float = 4.0

var _radius: float = 0.0


func _ready() -> void:
	visible = false


func _draw() -> void:
	if not visible:
		return

	draw_circle(Vector2.ZERO, _radius, fill_color)
	draw_circle(Vector2.ZERO, _radius, outline_color, false, outline_width, true)


func start() -> void:
	_radius = 0.0
	visible = true
	queue_redraw()


func set_radius(radius: float) -> void:
	assert(radius >= 0.0, "radius must not be negative.")
	_radius = radius
	queue_redraw()


func finish() -> void:
	visible = false
