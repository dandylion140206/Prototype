class_name CoinBox
extends Node2D

const RADIUS: float = 32.0
const BORDER_WIDTH: float = 4.0
const BORDER_COLOR := Color("#7A5A22")
const FILL_COLOR := Color("#F6C945")

var _collect_tween: Tween


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, BORDER_COLOR)
	draw_circle(Vector2.ZERO, RADIUS - BORDER_WIDTH, FILL_COLOR)


func play_collect_animation() -> void:
	if _collect_tween != null and _collect_tween.is_valid():
		_collect_tween.kill()

	scale = Vector2.ONE
	_collect_tween = create_tween()
	_collect_tween.set_trans(Tween.TRANS_QUAD)
	_collect_tween.set_ease(Tween.EASE_OUT)
	_collect_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	_collect_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
