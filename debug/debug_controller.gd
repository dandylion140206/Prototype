class_name DebugController
extends Node

@export var enabled: bool = true
@export_range(0.05, 1.0, 0.05) var slow_time_scale: float = 0.35
@export var slow_key: Key = KEY_SHIFT


func _process(_delta: float) -> void:
	if not enabled:
		Engine.time_scale = 1.0
		return

	if Input.is_key_pressed(slow_key):
		Engine.time_scale = slow_time_scale
	else:
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0
