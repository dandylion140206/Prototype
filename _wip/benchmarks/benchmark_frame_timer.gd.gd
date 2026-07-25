class_name BenchmarkFrameTimer
extends RefCounted

var _total_usec: int = 0
var _max_usec: int = 0
var _sample_count: int = 0


func add_sample(usec: int) -> void:
	_total_usec += usec
	_max_usec = maxi(_max_usec, usec)
	_sample_count += 1


func reset() -> void:
	_total_usec = 0
	_max_usec = 0
	_sample_count = 0


func get_average_ms() -> float:
	if _sample_count == 0:
		return 0.0

	return _total_usec / float(_sample_count) / 1000.0


func get_max_ms() -> float:
	return _max_usec / 1000.0
