class_name HitScaleReaction
extends Node

signal reaction_started
signal reaction_finished
enum ReactionMode {
	SPRING,
	TWEEN,
}

@export var enabled: bool = true
@export var reaction_mode: ReactionMode = ReactionMode.SPRING
@export_range(0.01, 1.0, 0.01) var scale_pull: float = 0.25
@export_range(0.01, 1.0, 0.01) var min_scale_value: float = 0.5
@export_range(1.0, 5.0, 0.01) var max_scale_value: float = 1.5

@export_group("Spring", "spring_")
@export_range(1.0, 1000.0, 1.0) var spring_stiffness: float = 200.0
@export_range(0.0, 100.0, 0.1) var spring_damping: float = 10.0
@export_range(0.001, 0.1, 0.001, "suffix:s") var spring_step: float = 0.008
@export_range(1, 32, 1) var spring_max_substeps: int = 8
@export_range(0.001, 1.0, 0.001, "suffix:s") var spring_max_frame_delta: float = 0.067
@export_range(0.0, 100.0, 0.1) var spring_max_scale_velocity: float = 20.0
@export_range(0.0001, 0.1, 0.0001) var spring_settle_distance: float = 0.001
@export_range(0.001, 1.0, 0.001) var spring_settle_velocity: float = 0.01

@export_group("Tween", "tween_")
@export_range(0.01, 1.0, 0.01, "suffix:s") var tween_duration: float = 0.2
@export var tween_transition: Tween.TransitionType = Tween.TRANS_ELASTIC
@export var tween_ease: Tween.EaseType = Tween.EASE_OUT

var _target: Node2D
var _scale_applier: Callable
var _base_scale: Vector2 = Vector2.ONE
var _scale_value: float = 1.0
var _scale_velocity: float = 0.0
var _scale_tween: Tween
var _is_reacting: bool = false


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	if not enabled:
		_reset()
		return

	if reaction_mode == ReactionMode.TWEEN:
		return

	var remaining_time := minf(delta, spring_max_frame_delta)
	var substep_count := 0
	while remaining_time > 0.0 and substep_count < spring_max_substeps:
		var step := minf(remaining_time, spring_step)
		_update_spring(step)
		remaining_time -= step
		substep_count += 1

	_apply_scale()
	if _has_settled():
		_set_scale_value(1.0)
		_scale_velocity = 0.0
		_finish_reaction()


func setup(target: Node2D, scale_applier: Callable = Callable()) -> void:
	assert(target != null, "target must not be null.")

	_target = target
	_scale_applier = scale_applier
	_base_scale = target.scale
	_scale_value = 1.0
	_scale_velocity = 0.0
	_is_reacting = false


func play() -> void:
	assert(_target != null, "HitScaleReaction must be setup before play().")

	if not enabled:
		return

	if _scale_tween != null:
		_scale_tween.kill()

	_scale_value = clampf(_scale_value + scale_pull, min_scale_value, max_scale_value)
	_start_reaction()
	_apply_scale()

	if reaction_mode == ReactionMode.SPRING:
		return

	_scale_velocity = 0.0
	_scale_tween = create_tween()
	_scale_tween.tween_method(_set_scale_value, _scale_value, 1.0, tween_duration).set_trans(tween_transition).set_ease(tween_ease)
	_scale_tween.tween_callback(_finish_tween_reaction)


func _update_spring(delta: float) -> void:
	var acceleration := -spring_stiffness * (_scale_value - 1.0)
	acceleration -= spring_damping * _scale_velocity
	_scale_velocity = clampf(
		_scale_velocity + acceleration * delta,
		-spring_max_scale_velocity,
		spring_max_scale_velocity
	)
	_scale_value = clampf(_scale_value + _scale_velocity * delta, min_scale_value, max_scale_value)


func _finish_tween_reaction() -> void:
	_scale_tween = null
	_set_scale_value(1.0)
	_scale_velocity = 0.0
	_finish_reaction()


func _start_reaction() -> void:
	if _is_reacting:
		return

	_is_reacting = true
	reaction_started.emit()


func _finish_reaction() -> void:
	if not _is_reacting:
		return

	_is_reacting = false
	reaction_finished.emit()


func _has_settled() -> bool:
	return absf(_scale_value - 1.0) <= spring_settle_distance \
		and absf(_scale_velocity) <= spring_settle_velocity


func _set_scale_value(scale_value: float) -> void:
	_scale_value = scale_value
	_apply_scale()


func _apply_scale() -> void:
	if _scale_applier.is_valid():
		_scale_applier.call(_scale_value)
		return

	_target.scale = _base_scale * _scale_value


func _reset() -> void:
	if _scale_tween != null:
		_scale_tween.kill()
		_scale_tween = null

	_scale_value = 1.0
	_scale_velocity = 0.0
	_apply_scale()
	_finish_reaction()
