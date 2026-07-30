class_name InputController
extends Node

signal primary_ability_requested
signal secondary_ability_requested


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_action"):
		primary_ability_requested.emit()
		get_viewport().set_input_as_handled()
		return

	if get_viewport().is_input_handled():
		return

	if not event.is_action_pressed("secondary_action"):
		return

	secondary_ability_requested.emit()
	get_viewport().set_input_as_handled()
