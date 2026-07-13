class_name Hitbox
extends Area2D

signal hit_detected(hurtbox: Hurtbox)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return

	hit_detected.emit(area as Hurtbox)
