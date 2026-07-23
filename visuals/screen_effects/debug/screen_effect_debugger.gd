class_name ScreenEffectDebugger
extends CanvasLayer

signal panel_visibility_changed(is_visible: bool)

@export var screen_effect_stack: ScreenEffectStack

var _preset_names: Array[String] = []
var _pending_preset_name: String = ""

@onready var _debug_window: Control = $ScreenEffectDebugWindow
@onready var _master_enabled: CheckBox = %MasterEnabled
@onready var _preset_selector: OptionButton = %PresetSelector
@onready var _save_button: Button = %SaveButton
@onready var _save_as_button: Button = %SaveAsButton
@onready var _delete_button: Button = %DeleteButton
@onready var _reset_all_button: Button = %ResetAllButton
@onready var _effect_list: VBoxContainer = %EffectList
@onready var _reset_all_dialog: ConfirmationDialog = %ResetAllDialog
@onready var _delete_preset_dialog: ConfirmationDialog = %DeletePresetDialog
@onready var _discard_changes_dialog: ConfirmationDialog = %DiscardChangesDialog
@onready var _save_as_preset_dialog: ConfirmationDialog = %SaveAsPresetDialog
@onready var _preset_name_input: LineEdit = %PresetNameInput


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	assert(screen_effect_stack != null, "ScreenEffectStack must not be null")
	assert(_debug_window != null, "ScreenEffectDebugWindow must not be null")
	assert(_effect_list != null, "EffectList must not be null")

	_debug_window.hide()
	_debug_window.visibility_changed.connect(_on_debug_window_visibility_changed)
	_master_enabled.toggled.connect(_on_master_enabled_toggled)
	_preset_selector.item_selected.connect(_on_preset_selected)
	_save_button.pressed.connect(_on_save_button_pressed)
	_save_as_button.pressed.connect(_on_save_as_button_pressed)
	_delete_button.pressed.connect(_on_delete_button_pressed)
	_reset_all_button.pressed.connect(_on_reset_all_button_pressed)
	_reset_all_dialog.confirmed.connect(_on_reset_all_confirmed)
	_delete_preset_dialog.confirmed.connect(_on_delete_preset_confirmed)
	_discard_changes_dialog.confirmed.connect(_on_discard_changes_confirmed)
	_save_as_preset_dialog.confirmed.connect(_on_save_as_preset_confirmed)
	screen_effect_stack.enabled_changed.connect(_on_stack_enabled_changed)
	screen_effect_stack.preset_changed.connect(_on_preset_changed)
	screen_effect_stack.preset_dirty_changed.connect(_on_preset_dirty_changed)

	_create_effect_editors(screen_effect_stack.get_states())
	_refresh_preset_controls()
	_master_enabled.set_pressed_no_signal(screen_effect_stack.enabled)
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


func _on_master_enabled_toggled(enabled: bool) -> void:
	screen_effect_stack.enabled = enabled


func _on_stack_enabled_changed(enabled: bool) -> void:
	_master_enabled.set_pressed_no_signal(enabled)


func _on_preset_selected(index: int) -> void:
	assert(index >= 0 and index < _preset_names.size(), "Invalid preset index: %s" % index)

	var preset_name := _preset_names[index]

	if preset_name == screen_effect_stack.get_active_preset_name():
		return

	if screen_effect_stack.is_preset_dirty():
		_pending_preset_name = preset_name
		_refresh_preset_controls()
		_discard_changes_dialog.popup_centered()
		return

	_select_preset(preset_name)


func _on_save_button_pressed() -> void:
	var error := screen_effect_stack.save_active_preset()

	if error != OK:
		push_error("Failed to save screen effect preset: %s" % error)


func _on_save_as_button_pressed() -> void:
	_preset_name_input.clear()
	_save_as_preset_dialog.popup_centered()
	_preset_name_input.grab_focus()


func _on_delete_button_pressed() -> void:
	_delete_preset_dialog.popup_centered()


func _on_reset_all_button_pressed() -> void:
	_reset_all_dialog.popup_centered()


func _on_reset_all_confirmed() -> void:
	screen_effect_stack.reset_all()


func _on_delete_preset_confirmed() -> void:
	var error := screen_effect_stack.delete_active_preset()

	if error != OK:
		push_error("Failed to delete screen effect preset: %s" % error)


func _on_discard_changes_confirmed() -> void:
	if _pending_preset_name.is_empty():
		return

	var preset_name := _pending_preset_name
	_pending_preset_name = ""
	_select_preset(preset_name)


func _on_save_as_preset_confirmed() -> void:
	var error := screen_effect_stack.save_as_preset(_preset_name_input.text)

	if error != OK:
		push_error("Failed to save screen effect preset: %s" % error)


func _on_preset_changed(_preset_name: String) -> void:
	_refresh_preset_controls()


func _on_preset_dirty_changed(_is_dirty: bool) -> void:
	_refresh_preset_controls()


func _select_preset(preset_name: String) -> void:
	var error := screen_effect_stack.select_preset(preset_name)

	if error != OK:
		push_error("Failed to select screen effect preset: %s" % error)


func _emit_panel_visibility() -> void:
	panel_visibility_changed.emit(_debug_window.visible)


func _create_effect_editors(states: Array[ScreenEffectState]) -> void:
	_clear_effect_editors()

	for index in states.size():
		if index > 0:
			_effect_list.add_child(HSeparator.new())

		var state := states[index]
		assert(state != null, "ScreenEffectState must not be null")

		var editor := ScreenEffectEditor.new()
		_effect_list.add_child(editor)
		editor.setup(state)


func _clear_effect_editors() -> void:
	for child in _effect_list.get_children():
		_effect_list.remove_child(child)
		child.queue_free()


func _refresh_preset_controls() -> void:
	_preset_names = screen_effect_stack.get_preset_names()
	_preset_selector.clear()

	var active_preset_name := screen_effect_stack.get_active_preset_name()
	var active_index := 0

	for index in _preset_names.size():
		var preset_name := _preset_names[index]
		var display_name := preset_name

		if preset_name == active_preset_name and screen_effect_stack.is_preset_dirty():
			display_name += " *"

		_preset_selector.add_item(display_name)

		if preset_name == active_preset_name:
			active_index = index

	_preset_selector.select(active_index)

	var is_default_preset := active_preset_name == ScreenEffectPresetStore.DEFAULT_PRESET_NAME
	_save_button.disabled = is_default_preset
	_delete_button.disabled = is_default_preset
