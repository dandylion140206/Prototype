class_name Coin
extends Node2D

signal collected

const OUTER_RADIUS: float = 10.0
const INNER_RADIUS: float = 8.0
const MOVE_DURATION: float = 0.6
const REPEL_DISTANCE: float = 80.0
const REPEL_DURATION: float = 0.12

var _is_collecting: bool = false


func _draw() -> void:
	draw_circle(Vector2.ZERO, OUTER_RADIUS, Color("#F6C945"))
	draw_circle(Vector2.ZERO, INNER_RADIUS, Color("#FFE680"))


func collect_to(target_global_position: Vector2) -> void:
	if _is_collecting:
		return

	_is_collecting = true
	var repel_direction := (global_position - target_global_position).normalized()
	if repel_direction == Vector2.ZERO:
		repel_direction = Vector2.UP

	var repel_global_position := global_position + repel_direction * REPEL_DISTANCE
	var move_tween := create_tween()
	move_tween.set_trans(Tween.TRANS_QUAD)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "global_position", repel_global_position, REPEL_DURATION)
	move_tween.set_ease(Tween.EASE_IN)
	move_tween.tween_property(
		self,
		"global_position",
		target_global_position,
		MOVE_DURATION - REPEL_DURATION
	)
	move_tween.finished.connect(_on_collect_tween_finished)

	var scale_tween := create_tween()
	scale_tween.tween_property(self, "scale", Vector2(0.8, 0.8), MOVE_DURATION)


func _on_collect_tween_finished() -> void:
	collected.emit()
	queue_free()
