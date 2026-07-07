extends Line2D

@export var target: Node2D
@export_range(1, 500, 1) var max_points: int = 200
@export_range(0.0, 32.0, 0.1) var min_distance: float = 4.0
@export_range(0.0, 1.0, 0.01) var point_lifetime: float = 0.15
@export_range(2, 32, 1) var gradient_transition_point_count: int = 8

var _point_ages: Array[float] = []
var _is_emitting := true

var _is_lifetime_transitioning := false
var _lifetime_transition_start := 0.0
var _lifetime_transition_target := 0.0
var _lifetime_transition_duration := 0.0
var _lifetime_transition_elapsed := 0.0

var _is_gradient_transitioning := false
var _gradient_transition_start_colors := PackedColorArray()
var _gradient_transition_target_colors := PackedColorArray()
var _gradient_transition_offsets := PackedFloat32Array()
var _gradient_transition_target: Gradient
var _gradient_transition_duration := 0.0
var _gradient_transition_elapsed := 0.0


func _ready() -> void:
	clear_points()
	_point_ages.clear()


func _process(delta: float) -> void:
	_update_point_lifetime_transition(delta)
	_update_trail_gradient_transition(delta)
	_update_point_ages(delta)

	if target == null:
		return

	var local_point_position := to_local(target.global_position)

	if not _is_emitting:
		_update_last_point_position(local_point_position)
		return

	if point_lifetime <= 0.0:
		return

	var point_count := get_point_count()

	if point_count > 0:
		var last_point_position := get_point_position(point_count - 1)

		if local_point_position.distance_to(last_point_position) < min_distance:
			return

	add_point(local_point_position)
	_point_ages.append(0.0)

	while get_point_count() > max_points:
		_remove_oldest_point()


func set_emitting(enabled: bool) -> void:
	if _is_emitting == enabled:
		return

	_is_emitting = enabled

	if _is_emitting:
		clear_trail()


func is_emitting() -> bool:
	return _is_emitting


func clear_trail() -> void:
	clear_points()
	_point_ages.clear()


func set_point_lifetime(value: float) -> void:
	if value < 0.0:
		push_warning("point_lifetime was clamped to 0.0.")

	point_lifetime = maxf(value, 0.0)
	_is_lifetime_transitioning = false


func transition_point_lifetime(value: float, duration: float) -> void:
	if value < 0.0:
		push_warning("point_lifetime transition target was clamped to 0.0.")

	var target_lifetime := maxf(value, 0.0)

	if duration <= 0.0:
		set_point_lifetime(target_lifetime)
		return

	_is_lifetime_transitioning = true
	_lifetime_transition_start = point_lifetime
	_lifetime_transition_target = target_lifetime
	_lifetime_transition_duration = duration
	_lifetime_transition_elapsed = 0.0


func set_trail_gradient(new_gradient: Gradient) -> void:
	gradient = new_gradient
	_is_gradient_transitioning = false
	_gradient_transition_start_colors.clear()
	_gradient_transition_target_colors.clear()
	_gradient_transition_offsets.clear()
	_gradient_transition_target = null


func transition_trail_gradient(new_gradient: Gradient, duration: float) -> void:
	if duration <= 0.0:
		set_trail_gradient(new_gradient)
		return

	_is_gradient_transitioning = true
	_gradient_transition_start_colors.clear()
	_gradient_transition_target_colors.clear()
	_gradient_transition_offsets.clear()

	var sample_count := gradient_transition_point_count

	if sample_count < 2:
		sample_count = 2

	for i in range(sample_count):
		var offset := float(i) / float(sample_count - 1)

		_gradient_transition_offsets.append(offset)
		_gradient_transition_start_colors.append(_sample_gradient_or_default(gradient, offset))
		_gradient_transition_target_colors.append(_sample_gradient_or_default(new_gradient, offset))

	_gradient_transition_target = new_gradient
	_gradient_transition_duration = duration
	_gradient_transition_elapsed = 0.0


func _update_point_lifetime_transition(delta: float) -> void:
	if not _is_lifetime_transitioning:
		return

	_lifetime_transition_elapsed += delta

	var progress := _lifetime_transition_elapsed / _lifetime_transition_duration
	progress = clampf(progress, 0.0, 1.0)

	point_lifetime = lerpf(
		_lifetime_transition_start,
		_lifetime_transition_target,
		progress
	)

	if progress >= 1.0:
		point_lifetime = _lifetime_transition_target
		_is_lifetime_transitioning = false


func _update_trail_gradient_transition(delta: float) -> void:
	if not _is_gradient_transitioning:
		return

	_gradient_transition_elapsed += delta

	var progress := _gradient_transition_elapsed / _gradient_transition_duration
	progress = clampf(progress, 0.0, 1.0)

	var colors := PackedColorArray()

	for i in range(_gradient_transition_offsets.size()):
		var color := _gradient_transition_start_colors[i].lerp(
			_gradient_transition_target_colors[i],
			progress
		)

		colors.append(color)

	var transition_gradient := Gradient.new()
	transition_gradient.offsets = _gradient_transition_offsets
	transition_gradient.colors = colors
	gradient = transition_gradient

	if progress >= 1.0:
		gradient = _gradient_transition_target
		_is_gradient_transitioning = false
		_gradient_transition_start_colors.clear()
		_gradient_transition_target_colors.clear()
		_gradient_transition_offsets.clear()
		_gradient_transition_target = null


func _update_point_ages(delta: float) -> void:
	for i in range(_point_ages.size()):
		_point_ages[i] += delta

	while _point_ages.size() > 0 and _point_ages[0] >= point_lifetime:
		_remove_oldest_point()


func _update_last_point_position(local_point_position: Vector2) -> void:
	var point_count := get_point_count()

	if point_count == 0:
		return

	set_point_position(point_count - 1, local_point_position)


func _sample_gradient_or_default(target_gradient: Gradient, offset: float) -> Color:
	if target_gradient == null:
		return default_color

	return target_gradient.sample(offset)


func _remove_oldest_point() -> void:
	assert(get_point_count() > 0, "Cannot remove point because Trail has no points.")
	assert(_point_ages.size() > 0, "Cannot remove point age because Trail has no point ages.")

	remove_point(0)
	_point_ages.remove_at(0)
