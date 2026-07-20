class_name EffectUI
extends CanvasLayer

signal panel_visibility_changed(is_visible: bool)

@onready var _floating_panel: Control = $FloatingPanel


func _ready() -> void:
	_floating_panel.hide()
	_floating_panel.visibility_changed.connect(_on_floating_panel_visibility_changed)
	_emit_panel_visibility()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().gui_release_focus()

	elif event is InputEventKey:
		var key_event := event as InputEventKey

		if (
			key_event.pressed
			and not key_event.echo
			and key_event.keycode == KEY_F1
		):
			_floating_panel.visible = not _floating_panel.visible
			get_viewport().set_input_as_handled()


func _on_floating_panel_visibility_changed() -> void:
	_emit_panel_visibility()


func _emit_panel_visibility() -> void:
	panel_visibility_changed.emit(_floating_panel.visible)
