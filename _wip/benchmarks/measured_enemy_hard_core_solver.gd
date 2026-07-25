class_name MeasuredEnemyHardCoreSolver
extends EnemyHardCoreSolver

var _timer: BenchmarkFrameTimer = BenchmarkFrameTimer.new()


func _physics_process(delta: float) -> void:
	var start_usec := Time.get_ticks_usec()
	super._physics_process(delta)
	_timer.add_sample(Time.get_ticks_usec() - start_usec)


func get_timer() -> BenchmarkFrameTimer:
	return _timer
