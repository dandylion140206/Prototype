class_name HitFlash
extends Node

@export var flash_modulate: Color = Color(3.0, 3.0, 3.0, 1.0)
@export_range(0.01, 1.0, 0.01, "suffix:s") var flash_duration: float = 0.2
@export var flash_transition: Tween.TransitionType = Tween.TRANS_QUAD
@export var flash_ease: Tween.EaseType = Tween.EASE_OUT

var _target: CanvasItem
var _flash_tween: Tween


func setup(target: CanvasItem) -> void:
	assert(target != null, "target must not be null.")

	_target = target


func play() -> void:
	assert(_target != null, "HitFlash must be setup before play().")

	if _flash_tween != null:
		_flash_tween.kill()

	_target.self_modulate = flash_modulate
	_flash_tween = create_tween()
	_flash_tween.tween_property(
		_target,
		"self_modulate",
		Color.WHITE,
		flash_duration
	).set_trans(flash_transition).set_ease(flash_ease)
