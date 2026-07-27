class_name HitSweepResult
extends RefCounted

var collisions: Array[BallHitCollision]
var unsafe_fraction: float


func _init(
	p_collisions: Array[BallHitCollision],
	p_unsafe_fraction: float
) -> void:
	assert(
		p_unsafe_fraction >= 0.0 and p_unsafe_fraction <= 1.0,
		"p_unsafe_fraction must be between 0.0 and 1.0."
	)

	collisions = p_collisions
	unsafe_fraction = p_unsafe_fraction
