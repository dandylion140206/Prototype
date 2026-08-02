class_name EnemySpawnAnimation
extends Node

signal finished
signal hit_detection_ready

enum AnimationPhase {
	GROW,
	SETTLE,
	COMPLETE,
}

@export var initial_scale: Vector2 = Vector2(0.1, 0.1)
@export var peak_scale: Vector2 = Vector2(1.3, 1.3)
@export_range(0.01, 2.0, 0.01, "suffix:s") var grow_duration: float = 0.12
@export var grow_transition: Tween.TransitionType = Tween.TRANS_QUAD
@export var grow_ease: Tween.EaseType = Tween.EASE_OUT
@export_range(0.0, 5.0, 0.01, "suffix:s") var hurtbox_enable_delay: float = 0.12

@export_group("Spring", "spring_")
@export_range(1.0, 1000.0, 1.0) var spring_stiffness: float = 200.0
@export_range(0.0, 100.0, 0.1) var spring_damping: float = 10.0
@export_range(0.001, 0.1, 0.001, "suffix:s") var spring_step: float = 0.008
@export_range(1, 32, 1) var spring_max_substeps: int = 8
@export_range(0.001, 1.0, 0.001, "suffix:s") var spring_max_frame_delta: float = 0.067
@export_range(0.0, 100.0, 0.1) var spring_max_scale_velocity: float = 20.0
@export_range(0.0001, 0.1, 0.0001) var spring_settle_distance: float = 0.001
@export_range(0.001, 1.0, 0.001) var spring_settle_velocity: float = 0.01

var _scale_applier: Callable
var _current_scale: Vector2 = Vector2.ONE
var _scale_velocity: Vector2 = Vector2.ZERO
var _phase: AnimationPhase = AnimationPhase.COMPLETE
var _grow_tween: Tween
var _elapsed_time: float = 0.0
var _has_enabled_hit_detection: bool = false


func _process(delta: float) -> void:
	if _phase == AnimationPhase.COMPLETE:
		return

	_elapsed_time += delta
	_emit_hit_detection_ready_if_needed()
	if _phase != AnimationPhase.SETTLE:
		return

	var remaining_time := minf(delta, spring_max_frame_delta)
	var substep_count := 0
	while remaining_time > 0.0 and substep_count < spring_max_substeps:
		var step := minf(remaining_time, spring_step)
		_update_spring(step)
		remaining_time -= step
		substep_count += 1

	_apply_scale(_current_scale)
	if _has_settled():
		_apply_scale(Vector2.ONE)
		_phase = AnimationPhase.COMPLETE
		finished.emit()


func setup(scale_applier: Callable) -> void:
	assert(scale_applier.is_valid(), "scale_applier must be valid.")

	_scale_applier = scale_applier


func play() -> void:
	assert(_scale_applier.is_valid(), "EnemySpawnAnimation must be setup before play().")

	_stop_grow_tween()
	_phase = AnimationPhase.GROW
	_current_scale = initial_scale
	_scale_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_has_enabled_hit_detection = false
	_apply_scale(initial_scale)
	_emit_hit_detection_ready_if_needed()
	_grow_tween = create_tween()
	_grow_tween.tween_method(_apply_scale, initial_scale, peak_scale, grow_duration).set_trans(grow_transition).set_ease(grow_ease)
	_grow_tween.finished.connect(_on_grow_tween_finished)


func _on_grow_tween_finished() -> void:
	_grow_tween = null
	_current_scale = peak_scale
	_scale_velocity = Vector2.ZERO
	_phase = AnimationPhase.SETTLE


func _emit_hit_detection_ready_if_needed() -> void:
	if _has_enabled_hit_detection or _elapsed_time < hurtbox_enable_delay:
		return

	_has_enabled_hit_detection = true
	hit_detection_ready.emit()


func _update_spring(delta: float) -> void:
	var acceleration := -spring_stiffness * (_current_scale - Vector2.ONE)
	acceleration -= spring_damping * _scale_velocity
	_scale_velocity = (_scale_velocity + acceleration * delta).limit_length(spring_max_scale_velocity)
	_current_scale += _scale_velocity * delta


func _has_settled() -> bool:
	return _current_scale.distance_to(Vector2.ONE) <= spring_settle_distance \
		and _scale_velocity.length() <= spring_settle_velocity


func _apply_scale(scale_value: Vector2) -> void:
	_current_scale = scale_value
	_scale_applier.call(scale_value)


func _stop_grow_tween() -> void:
	if _grow_tween == null:
		return

	_grow_tween.kill()
	_grow_tween = null
