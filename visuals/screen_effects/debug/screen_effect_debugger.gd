class_name ScreenEffectDebugger
extends CanvasLayer

signal panel_visibility_changed(is_visible: bool)

@export var screen_effect_stack: ScreenEffectStack

@onready var _debug_window: Control = $ScreenEffectDebugWindow
@onready var _effect_list: VBoxContainer = %EffectList


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	assert(screen_effect_stack != null, "ScreenEffectStack must not be null")
	assert(_debug_window != null, "ScreenEffectDebugWindow must not be null")
	assert(_effect_list != null, "EffectList must not be null")

	_debug_window.hide()
	_debug_window.visibility_changed.connect(_on_debug_window_visibility_changed)
	_create_effect_editors(screen_effect_stack.get_states())
	_emit_panel_visibility()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().gui_release_focus()

	elif event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F1:
			_debug_window.visible = not _debug_window.visible
			get_viewport().set_input_as_handled()


func _on_debug_window_visibility_changed() -> void:
	_emit_panel_visibility()


func _emit_panel_visibility() -> void:
	panel_visibility_changed.emit(_debug_window.visible)


func _create_effect_editors(states: Array[ScreenEffectState]) -> void:
	_clear_effect_editors()

	for state in states:
		assert(state != null, "ScreenEffectState must not be null")

		var editor := ScreenEffectEditor.new()
		_effect_list.add_child(editor)
		editor.setup(state)


func _clear_effect_editors() -> void:
	for child in _effect_list.get_children():
		_effect_list.remove_child(child)
		child.queue_free()
