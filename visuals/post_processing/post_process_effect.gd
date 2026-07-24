@tool
class_name PostProcessEffect
extends Resource

@export var enabled: bool = true:
	set(value):
		if enabled == value:
			return

		enabled = value
		notify_change()

var shader_parameters: Dictionary[StringName, Variant] = {}


func _get_shader() -> Shader:
	return null


func _update_shader_parameters() -> void:
	pass


func notify_change() -> void:
	emit_changed()
