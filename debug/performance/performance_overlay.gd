class_name PerformanceOverlay
extends CanvasLayer

const MILLISECONDS_PER_SECOND := 1000.0

@export_range(0.05, 3.0, 0.05) var update_interval := 0.10

@onready var _label: Label = $Label

var _viewport_rid: RID
var _last_update_time_msec := 0
var _fps := 0.0
var _frame_time_msec := 0.0
var _cpu_render_time_msec := 0.0
var _gpu_render_time_msec := 0.0
var _draw_calls := 0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_viewport_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport_rid, true)
	visible = true
	_update_performance_display()


func _process(_delta: float) -> void:
	var current_time_msec := Time.get_ticks_msec()

	if current_time_msec - _last_update_time_msec < update_interval * MILLISECONDS_PER_SECOND:
		return

	_last_update_time_msec = current_time_msec
	_update_performance_display()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if (
		not key_event.pressed
		or key_event.echo
		or key_event.keycode != KEY_BACKSPACE
	):
		return

	visible = not visible
	get_viewport().set_input_as_handled()


func _update_performance_display() -> void:
	_fps = float(Performance.get_monitor(Performance.TIME_FPS))
	_frame_time_msec = float(Performance.get_monitor(Performance.TIME_PROCESS)) * MILLISECONDS_PER_SECOND
	_cpu_render_time_msec = (
		RenderingServer.get_frame_setup_time_cpu()
		+ RenderingServer.viewport_get_measured_render_time_cpu(_viewport_rid)
	)
	_gpu_render_time_msec = RenderingServer.viewport_get_measured_render_time_gpu(_viewport_rid)
	_draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	_label.text = (
		"FPS: %.0f\n"
		+ "Frame Time: %.2f ms\n"
		+ "CPU Render Time: %.2f ms\n"
		+ "GPU Render Time: %.2f ms\n"
		+ "Draw Calls: %d"
	) % [
		_fps,
		_frame_time_msec,
		_cpu_render_time_msec,
		_gpu_render_time_msec,
		_draw_calls,
	]
