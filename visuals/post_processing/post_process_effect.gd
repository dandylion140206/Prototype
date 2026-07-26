@tool
@abstract
class_name PostProcessEffect
extends Resource

var shader_parameters: Dictionary[StringName, Variant] = {}


@abstract
func _get_shader() -> Shader


@abstract
func _update_shader_parameters() -> void


func is_enabled() -> bool:
	return bool(get("enabled"))


func notify_change() -> void:
	emit_changed()
