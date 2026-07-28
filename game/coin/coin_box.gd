class_name CoinBox
extends Node2D

const RADIUS: float = 32.0
const BORDER_WIDTH: float = 4.0
const BORDER_COLOR := Color("#7A5A22")
const FILL_COLOR := Color("#F6C945")
const COIN_COUNT_REFERENCE: float = 100.0
const MAX_SIZE_SCALE: float = 3.0

var _collect_tween: Tween
var _size_scale: float = 1.0
var _pulse_scale: float = 1.0:
	set(value):
		_pulse_scale = value
		_apply_scale()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, BORDER_COLOR)
	draw_circle(Vector2.ZERO, RADIUS - BORDER_WIDTH, FILL_COLOR)


func set_coin_count(coin_count: int) -> void:
	var normalized_count := clampf(float(coin_count), 0.0, COIN_COUNT_REFERENCE)
	normalized_count /= COIN_COUNT_REFERENCE
	_size_scale = 1.0 + (MAX_SIZE_SCALE - 1.0) * sqrt(normalized_count)
	_apply_scale()


func play_collect_animation() -> void:
	if _collect_tween != null and _collect_tween.is_valid():
		_collect_tween.kill()

	_pulse_scale = 1.0
	_collect_tween = create_tween()
	_collect_tween.set_trans(Tween.TRANS_QUAD)
	_collect_tween.set_ease(Tween.EASE_OUT)
	_collect_tween.tween_property(self, ^"_pulse_scale", 1.2, 0.1)
	_collect_tween.tween_property(self, ^"_pulse_scale", 1.0, 0.1)


func _apply_scale() -> void:
	scale = Vector2.ONE * _size_scale * _pulse_scale
