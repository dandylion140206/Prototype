class_name Knockback
extends Node

## 固定時間で減衰するノックバック速度を提供する。

signal knockback_finished

@export_range(0.05, 1.0, 0.05) var duration: float = 0.2

var velocity: Vector2 = Vector2.ZERO

var _tween: Tween = null


func start(impulse: Vector2) -> void:
	if _tween != null:
		_tween.kill()

	velocity = impulse
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "velocity", Vector2.ZERO, duration)
	_tween.finished.connect(_on_tween_finished)


func is_knocked_back() -> bool:
	return _tween != null


func _on_tween_finished() -> void:
	_tween = null
	velocity = Vector2.ZERO
	knockback_finished.emit()
