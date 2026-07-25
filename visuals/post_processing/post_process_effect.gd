@tool
class_name PostProcessEffect
extends Resource

var shader_parameters: Dictionary[StringName, Variant] = {}


func _get_shader() -> Shader:
	return null


func _update_shader_parameters() -> void:
	pass


func is_enabled() -> bool:
	return bool(get("enabled"))


func notify_change() -> void:
	emit_changed()
