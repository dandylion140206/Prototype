class_name Hurtbox
extends Area2D

signal hit_received(hit_data: HitData)

@export_range(0.0, 10.0, 0.01, "suffix:s") var rehit_cooldown: float = 0.1

var _last_hit_time_by_source_id: Dictionary[int, float] = {}


func receive_hit(hit_data: HitData) -> bool:
	assert(hit_data != null, "hit_data must not be null.")

	if not can_receive_hit(hit_data):
		return false

	_last_hit_time_by_source_id[hit_data.attack_source_id] = _get_current_time()
	hit_received.emit(hit_data)
	return true


func can_receive_hit(hit_data: HitData) -> bool:
	assert(hit_data != null, "hit_data must not be null.")

	var last_hit_time: float = _last_hit_time_by_source_id.get(
		hit_data.attack_source_id,
		-INF
	)
	return _get_current_time() - last_hit_time >= rehit_cooldown


func set_enabled(enabled: bool) -> void:
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)


func _get_current_time() -> float:
	return Time.get_ticks_msec() * 0.001
