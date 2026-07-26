class_name DebugController
extends Node

@export var enabled: bool = true
@export_range(0.05, 1.0, 0.05) var slow_time_scale: float = 0.25
@export var slow_key: Key = KEY_SHIFT
@export var restart_key: Key = KEY_R

var _base_physics_ticks_per_second: int
var _current_time_scale: float = -1.0


func _ready() -> void:
	_base_physics_ticks_per_second = (Engine.physics_ticks_per_second)
	_apply_time_scale(1.0)


func _process(_delta: float) -> void:
	var requested_time_scale := 1.0

	if enabled and Input.is_key_pressed(slow_key):
		requested_time_scale = slow_time_scale

	if is_equal_approx(
		requested_time_scale,
		_current_time_scale
	):
		return

	_apply_time_scale(requested_time_scale)


func _unhandled_key_input(event: InputEvent) -> void:
	if not enabled:
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode != restart_key:
		return

	get_viewport().set_input_as_handled()
	_reload_current_scene.call_deferred()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = (_base_physics_ticks_per_second)


func _reload_current_scene() -> void:
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Failed to reload current scene: %s" % error_string(error))


func _apply_time_scale(time_scale: float) -> void:
	assert(time_scale > 0.0, "time_scale must be positive.")

	var scaled_physics_ticks := roundi(_base_physics_ticks_per_second * time_scale)

	Engine.time_scale = time_scale
	Engine.physics_ticks_per_second = maxi(scaled_physics_ticks, 1)
	_current_time_scale = time_scale
