class_name HitEffect
extends Node

@export var flash_modulate: Color = Color(3.0, 3.0, 3.0, 1.0)
@export_range(0.01, 1.0, 0.01) var flash_duration: float = 0.2
@export var flash_transition: Tween.TransitionType = Tween.TRANS_QUAD
@export var flash_ease: Tween.EaseType = Tween.EASE_OUT
@export var scale_reaction_enabled: bool = true
@export_range(0.01, 1.0, 0.01) var scale_pull: float = 0.25
@export_range(1.0, 1000.0, 1.0) var spring_stiffness: float = 200.0
@export_range(0.0, 100.0, 0.1) var spring_damping: float = 10.0

var _target: Node2D
var _base_scale: Vector2 = Vector2.ONE
var _scale_value: float = 1.0
var _scale_velocity: float = 0.0
var _flash_tween: Tween


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	if not scale_reaction_enabled:
		_scale_value = 1.0
		_scale_velocity = 0.0
		_target.scale = _base_scale
		return

	var acceleration := -spring_stiffness * (_scale_value - 1.0)
	acceleration -= spring_damping * _scale_velocity
	_scale_velocity += acceleration * delta
	_scale_value += _scale_velocity * delta
	_target.scale = _base_scale * _scale_value


func setup(target: Node2D) -> void:
	assert(target != null, "target must not be null.")

	_target = target
	_base_scale = target.scale
	_scale_value = 1.0
	_scale_velocity = 0.0


func play() -> void:
	assert(_target != null, "HitEffect must be setup before play().")

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

	if scale_reaction_enabled:
		# SNKRX's Spring:pull adds the force to its current scale value.
		_scale_value += scale_pull

