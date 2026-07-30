class_name WanderingTestInputController
extends InputController

signal secondary_ability_requested


func _unhandled_input(event: InputEvent) -> void:
	super(event)

	if get_viewport().is_input_handled():
		return

	if not event.is_action_pressed("secondary_action"):
		return

	secondary_ability_requested.emit()
	get_viewport().set_input_as_handled()
