class_name PerformanceOverlayPanel
extends DebugOverlayPanel

const MILLISECONDS_PER_SECOND := 1000.0

var _viewport_rid: RID


func _ready() -> void:
	_viewport_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport_rid, true)


func update_display() -> void:
	var fps := float(Performance.get_monitor(Performance.TIME_FPS))
	var frame_time_msec := (
		float(Performance.get_monitor(Performance.TIME_PROCESS))
		* MILLISECONDS_PER_SECOND
	)
	var physics_time_msec := (
		float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
		* MILLISECONDS_PER_SECOND
	)
	var cpu_render_time_msec := (
		RenderingServer.get_frame_setup_time_cpu()
		+ RenderingServer.viewport_get_measured_render_time_cpu(_viewport_rid)
	)
	var gpu_render_time_msec := RenderingServer.viewport_get_measured_render_time_gpu(_viewport_rid)
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	text = (
		"FPS: %.0f\n"
		+ "Frame Time: %.2f ms\n"
		+ "Physics Time: %.2f ms\n"
		+ "CPU Render Time: %.2f ms\n"
		+ "GPU Render Time: %.2f ms\n"
		+ "Draw Calls: %d"
	) % [
		fps,
		frame_time_msec,
		physics_time_msec,
		cpu_render_time_msec,
		gpu_render_time_msec,
		draw_calls,
	]
