class_name ScreenEffectEditor
extends VBoxContainer

var _state: ScreenEffectState
var _enabled_checkbox: CheckBox
var _parameter_rows: Dictionary[StringName, Control] = {}
var _parameter_editors: Dictionary[StringName, Control] = {}
var _parameter_sliders: Dictionary[StringName, Slider] = {}
var _parameter_reset_buttons: Dictionary[StringName, Button] = {}


func setup(state: ScreenEffectState) -> void:
	assert(state != null, "ScreenEffectState must not be null")

	_disconnect_state()
	_clear_editors()

	_state = state

	_create_enabled_editor()

	for parameter in _state.parameters:
		_create_parameter_editor(parameter)

	_state.parameter_changed.connect(_on_state_parameter_changed)
	_state.enabled_changed.connect(_on_state_enabled_changed)

	_update_parameter_activation_states()


func _on_enabled_checkbox_toggled(enabled: bool) -> void:
	assert(_state != null, "ScreenEffectState must not be null")
	_state.enabled = enabled


func _on_effect_reset_pressed() -> void:
	assert(_state != null, "ScreenEffectState must not be null")
	_state.reset()


func _on_parameter_reset_pressed(parameter_id: StringName) -> void:
	assert(_state != null, "ScreenEffectState must not be null")
	_state.reset_parameter(parameter_id)


func _on_number_value_changed(value: float, parameter_id: StringName) -> void:
	assert(_state != null, "ScreenEffectState must not be null")
	_state.set_value(parameter_id, value)


func _on_boolean_toggled(value: bool, parameter_id: StringName) -> void:
	assert(_state != null, "ScreenEffectState must not be null")
	_state.set_value(parameter_id, value)


func _on_enum_item_selected(index: int, parameter_id: StringName) -> void:
	assert(_state != null, "ScreenEffectState must not be null")

	var parameter := _state.get_parameter(parameter_id)

	assert(
		index >= 0 and index < parameter.option_values.size(),
		"Invalid enum option index: %s" % index,
	)

	_state.set_value(parameter_id, parameter.option_values[index])


func _on_color_changed(value: Color, parameter_id: StringName) -> void:
	assert(_state != null, "ScreenEffectState must not be null")
	_state.set_value(parameter_id, value)


func _on_state_enabled_changed(enabled: bool) -> void:
	if _enabled_checkbox == null:
		return

	_enabled_checkbox.set_pressed_no_signal(enabled)
	_update_parameter_activation_states()


func _on_state_parameter_changed(id: StringName, value: Variant) -> void:
	_update_editor_value(id, value)
	_update_parameter_activation_states()


func _create_enabled_editor() -> void:
	var header := HBoxContainer.new()

	_enabled_checkbox = CheckBox.new()
	_enabled_checkbox.text = _state.display_name
	_enabled_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enabled_checkbox.set_pressed_no_signal(_state.enabled)
	_enabled_checkbox.toggled.connect(_on_enabled_checkbox_toggled)

	var reset_button := _create_reset_button("Reset effect")
	reset_button.pressed.connect(_on_effect_reset_pressed)

	header.add_child(_enabled_checkbox)
	header.add_child(reset_button)
	add_child(header)


func _create_parameter_editor(parameter: ScreenEffectParameterDefinition) -> void:
	match parameter.kind:
		ScreenEffectParameterDefinition.Kind.INTEGER:
			_create_number_editor(parameter, true)

		ScreenEffectParameterDefinition.Kind.FLOAT:
			_create_number_editor(parameter, false)

		ScreenEffectParameterDefinition.Kind.BOOLEAN:
			_create_boolean_editor(parameter)

		ScreenEffectParameterDefinition.Kind.ENUM:
			_create_enum_editor(parameter)

		ScreenEffectParameterDefinition.Kind.COLOR:
			_create_color_editor(parameter)

		_:
			assert(false, "Unsupported effect parameter kind: %s" % parameter.kind)


func _create_number_editor(
	parameter: ScreenEffectParameterDefinition,
	use_integer: bool,
) -> void:
	var row := VBoxContainer.new()
	var header := HBoxContainer.new()
	var label := Label.new()
	var spin_box := SpinBox.new()
	var slider := HSlider.new()
	var reset_button := _create_reset_button("Reset %s" % parameter.display_name)
	var value := float(_state.get_value(parameter.id))

	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	spin_box.min_value = parameter.min_value
	spin_box.max_value = parameter.max_value
	spin_box.step = parameter.step
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.rounded = use_integer

	spin_box.share(slider)
	slider.scrollable = false
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	spin_box.set_value_no_signal(value)
	spin_box.value_changed.connect(_on_number_value_changed.bind(parameter.id))

	header.add_child(label)
	header.add_child(spin_box)
	header.add_child(reset_button)

	reset_button.pressed.connect(_on_parameter_reset_pressed.bind(parameter.id))

	row.add_child(header)
	row.add_child(slider)
	add_child(row)

	_parameter_rows[parameter.id] = row
	_parameter_editors[parameter.id] = spin_box
	_parameter_sliders[parameter.id] = slider
	_parameter_reset_buttons[parameter.id] = reset_button


func _create_boolean_editor(parameter: ScreenEffectParameterDefinition) -> void:
	var row := HBoxContainer.new()
	var checkbox := CheckBox.new()
	var reset_button := _create_reset_button("Reset %s" % parameter.display_name)

	checkbox.text = parameter.display_name
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkbox.set_pressed_no_signal(bool(_state.get_value(parameter.id)))
	checkbox.toggled.connect(_on_boolean_toggled.bind(parameter.id))
	reset_button.pressed.connect(_on_parameter_reset_pressed.bind(parameter.id))

	row.add_child(checkbox)
	row.add_child(reset_button)
	add_child(row)

	_parameter_rows[parameter.id] = row
	_parameter_editors[parameter.id] = checkbox
	_parameter_reset_buttons[parameter.id] = reset_button


func _create_enum_editor(parameter: ScreenEffectParameterDefinition) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	var option_button := OptionButton.new()
	var reset_button := _create_reset_button("Reset %s" % parameter.display_name)

	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for option in parameter.options:
		option_button.add_item(option)

	_select_enum_value(option_button, parameter, int(_state.get_value(parameter.id)))
	option_button.item_selected.connect(_on_enum_item_selected.bind(parameter.id))

	row.add_child(label)
	row.add_child(option_button)
	row.add_child(reset_button)
	add_child(row)

	reset_button.pressed.connect(_on_parameter_reset_pressed.bind(parameter.id))

	_parameter_rows[parameter.id] = row
	_parameter_editors[parameter.id] = option_button
	_parameter_reset_buttons[parameter.id] = reset_button


func _create_color_editor(parameter: ScreenEffectParameterDefinition) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	var color_button := ColorPickerButton.new()
	var reset_button := _create_reset_button("Reset %s" % parameter.display_name)

	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_button.color = Color(_state.get_value(parameter.id))
	color_button.custom_minimum_size = Vector2(96.0, 0.0)
	color_button.get_picker().edit_alpha = true
	color_button.color_changed.connect(_on_color_changed.bind(parameter.id))
	reset_button.pressed.connect(_on_parameter_reset_pressed.bind(parameter.id))

	row.add_child(label)
	row.add_child(color_button)
	row.add_child(reset_button)
	add_child(row)

	_parameter_rows[parameter.id] = row
	_parameter_editors[parameter.id] = color_button
	_parameter_reset_buttons[parameter.id] = reset_button
func _update_editor_value(id: StringName, value: Variant) -> void:
	assert(_parameter_editors.has(id), "Parameter editor not found: %s" % id)

	var parameter := _state.get_parameter(id)
	var editor := _parameter_editors[id]

	match parameter.kind:
		ScreenEffectParameterDefinition.Kind.INTEGER, ScreenEffectParameterDefinition.Kind.FLOAT:
			assert(editor is SpinBox, "Numeric editor must be SpinBox: %s" % id)

			(editor as SpinBox).set_value_no_signal(float(value))

		ScreenEffectParameterDefinition.Kind.BOOLEAN:
			assert(editor is CheckBox, "Boolean editor must be CheckBox: %s" % id)
			(editor as CheckBox).set_pressed_no_signal(bool(value))

		ScreenEffectParameterDefinition.Kind.ENUM:
			assert(editor is OptionButton, "Enum editor must be OptionButton: %s" % id)
			_select_enum_value(editor as OptionButton, parameter, int(value))

		ScreenEffectParameterDefinition.Kind.COLOR:
			assert(editor is ColorPickerButton, "Color editor must be ColorPickerButton: %s" % id)
			(editor as ColorPickerButton).color = Color(value)

		_:
			assert(false, "Unsupported effect parameter kind: %s" % parameter.kind)


func _select_enum_value(
	option_button: OptionButton,
	parameter: ScreenEffectParameterDefinition,
	value: int,
) -> void:
	var option_index := parameter.get_option_index(value)

	assert(
		option_index >= 0,
		"Enum value '%s' was not found: %s" % [value, parameter.id],
	)

	option_button.select(option_index)


func _update_parameter_activation_states() -> void:
	assert(_state != null, "ScreenEffectState must not be null")

	for parameter in _state.parameters:
		assert(_parameter_rows.has(parameter.id), "Parameter row not found: %s" % parameter.id)
		assert(_parameter_editors.has(parameter.id), "Parameter editor not found: %s" % parameter.id)

		var is_active := _state.enabled and _state.is_parameter_active(parameter.id)
		var row := _parameter_rows[parameter.id]
		var editor := _parameter_editors[parameter.id]
		var reset_button := _parameter_reset_buttons[parameter.id]

		_set_editor_active(editor, is_active)
		reset_button.disabled = not is_active

		if _parameter_sliders.has(parameter.id):
			_parameter_sliders[parameter.id].editable = is_active

		_set_row_active_appearance(row, is_active)


func _set_editor_active(editor: Control, is_active: bool) -> void:
	if editor is BaseButton:
		(editor as BaseButton).disabled = not is_active
		return

	if editor is SpinBox:
		(editor as SpinBox).editable = is_active
		return

	assert(false, "Unsupported parameter editor: %s" % editor.get_class())


func _set_row_active_appearance(row: Control, is_active: bool) -> void:
	var color := row.modulate
	color.a = 1.0 if is_active else 0.5
	row.modulate = color


func _create_reset_button(tooltip: String) -> Button:
	var reset_button := Button.new()

	reset_button.custom_minimum_size = Vector2(32.0, 0.0)
	reset_button.tooltip_text = tooltip
	reset_button.text = "↺"

	return reset_button


func _disconnect_state() -> void:
	if _state == null:
		return

	if _state.parameter_changed.is_connected(_on_state_parameter_changed):
		_state.parameter_changed.disconnect(_on_state_parameter_changed)

	if _state.enabled_changed.is_connected(_on_state_enabled_changed):
		_state.enabled_changed.disconnect(_on_state_enabled_changed)

	_state = null


func _clear_editors() -> void:
	_enabled_checkbox = null
	_parameter_rows.clear()
	_parameter_editors.clear()
	_parameter_sliders.clear()
	_parameter_reset_buttons.clear()

	for child in get_children():
		remove_child(child)
		child.queue_free()
