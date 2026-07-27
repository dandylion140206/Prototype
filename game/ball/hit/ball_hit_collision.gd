class_name BallHitCollision
extends RefCounted

var hurtbox: Hurtbox
var position: Vector2


func _init(p_hurtbox: Hurtbox, p_position: Vector2) -> void:
	assert(p_hurtbox != null, "p_hurtbox must not be null.")

	hurtbox = p_hurtbox
	position = p_position
