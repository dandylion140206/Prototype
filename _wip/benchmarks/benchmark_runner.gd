class_name BenchmarkRunner
extends Node2D

enum SolverMode { BOTH, CROWD_ONLY, NONE }

@export var enemy_counts: PackedInt32Array = PackedInt32Array([100, 200, 300, 400, 500])
@export var solver_modes: Array[SolverMode] = [
	SolverMode.BOTH, SolverMode.CROWD_ONLY, SolverMode.NONE
]
@export_range(0, 3600, 1) var settle_frames: int = 180
@export_range(1, 3600, 1) var sample_frames: int = 120

@onready var _spawner: BenchmarkSpawner = %BenchmarkSpawner
@onready var _crowd_solver: MeasuredEnemyCrowdSolver = %EnemyCrowdSolver
@onready var _hard_core_solver: MeasuredEnemyHardCoreSolver = %EnemyHardCoreSolver


func _ready() -> void:
	await _run_all()


func _run_all() -> void:
	print("mode,enemy_count,crowd_ms,crowd_max_ms,hard_core_ms,hard_core_max_ms,physics_total_ms,physics_max_ms")

	for mode in solver_modes:
		for count in enemy_counts:
			await _run_case(mode, count)

	await _teardown_previous_case()
	print("done")
	get_tree().quit()


func _run_case(mode: SolverMode, count: int) -> void:
	await _teardown_previous_case()

	_spawner.spawn(count, self)
	_apply_mode(mode)

	for _frame in settle_frames:
		await get_tree().physics_frame

	_crowd_solver.get_timer().reset()
	_hard_core_solver.get_timer().reset()

	var physics_total_ms := 0.0
	var physics_max_ms := 0.0
	for _frame in sample_frames:
		await get_tree().physics_frame

		var physics_ms := (
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		)
		physics_total_ms += physics_ms
		physics_max_ms = maxf(physics_max_ms, physics_ms)

	var crowd_timer := _crowd_solver.get_timer()
	var hard_core_timer := _hard_core_solver.get_timer()
	print("%s,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f" % [
		SolverMode.keys()[mode],
		count,
		crowd_timer.get_average_ms(),
		crowd_timer.get_max_ms(),
		hard_core_timer.get_average_ms(),
		hard_core_timer.get_max_ms(),
		physics_total_ms / sample_frames,
		physics_max_ms,
	])


# 前ケースの敵を解放し、CrowdSolver の敵リストを空の状態へ更新させる。
# HardCoreSolver は CrowdSolver から敵リストを受け取るため、
# 解放済みノードを掴んだまま走らないよう先に停止しておく。
func _teardown_previous_case() -> void:
	_hard_core_solver.set_physics_process(false)
	_crowd_solver.set_physics_process(true)
	_spawner.clear()

	# 1フレーム目で queue_free() が処理され、2フレーム目で
	# CrowdSolver が空のリストを作り直す。
	await get_tree().physics_frame
	await get_tree().physics_frame


func _apply_mode(mode: SolverMode) -> void:
	# CrowdSolver は HardCoreSolver への敵リスト供給源を兼ねるため、
	# HardCoreSolver が有効な間は必ず有効にしておく。
	_hard_core_solver.set_physics_process(mode == SolverMode.BOTH)
	_crowd_solver.set_physics_process(mode != SolverMode.NONE)
