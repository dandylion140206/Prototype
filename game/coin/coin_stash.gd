class_name CoinStash
extends Node2D

const BORDER_WIDTH: float = 4.0
const BORDER_COLOR := Color("#7A5A22")
const FILL_COLOR := Color("#F6C945")
const ELLIPSE_SEGMENT_COUNT: int = 64

@export_group("Shape")
@export var size: Vector2 = Vector2(980.0, 320.0):
	set(value):
		size = Vector2(maxf(value.x, BORDER_WIDTH * 2.0), maxf(value.y, BORDER_WIDTH * 2.0))
		queue_redraw()

@export_group("Collect Animation")
@export var collect_scale: Vector2 = Vector2(1.2, 1.2):
	set(value):
		collect_scale = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))

var _collect_tween: Tween
var _pulse_scale: Vector2 = Vector2.ONE:
	set(value):
		_pulse_scale = value
		_apply_scale()


func _draw() -> void:
	var outer_radius := size * 0.5
	var inner_radius := outer_radius - Vector2.ONE * BORDER_WIDTH
	draw_colored_polygon(_create_ellipse_points(outer_radius), BORDER_COLOR)
	draw_colored_polygon(_create_ellipse_points(inner_radius), FILL_COLOR)


func get_collect_global_position() -> Vector2:
	return global_position


func play_collect_animation() -> void:
	if _collect_tween != null and _collect_tween.is_valid():
		_collect_tween.kill()

	_pulse_scale = Vector2.ONE
	_collect_tween = create_tween()
	_collect_tween.set_trans(Tween.TRANS_QUAD)
	_collect_tween.set_ease(Tween.EASE_OUT)
	_collect_tween.tween_property(self, ^"_pulse_scale", collect_scale, 0.1)
	_collect_tween.tween_property(self, ^"_pulse_scale", Vector2.ONE, 0.1)


func _apply_scale() -> void:
	scale = _pulse_scale


func _create_ellipse_points(radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(ELLIPSE_SEGMENT_COUNT)

	for index in ELLIPSE_SEGMENT_COUNT:
		var angle := TAU * float(index) / float(ELLIPSE_SEGMENT_COUNT)
		points[index] = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)

	return points
