class_name Hurtbox
extends Area2D

signal hit_received(hit_data: HitData)


func receive_hit(hit_data: HitData) -> void:
	assert(hit_data != null, "hit_data must not be null.")
	hit_received.emit(hit_data)


func set_enabled(enabled: bool) -> void:
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
