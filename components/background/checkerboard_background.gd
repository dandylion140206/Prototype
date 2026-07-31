@tool
class_name CheckerboardBackground
extends ColorRect

@export var coverage_size: Vector2 = Vector2(65536.0, 65536.0)


func _ready() -> void:
	assert(
		coverage_size.x > 0.0 and coverage_size.y > 0.0,
		"coverage_size must be greater than zero."
	)

	position = -coverage_size * 0.5
	size = coverage_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -100
