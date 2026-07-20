class_name EffectPanel
extends VBoxContainer

var _model: EffectModel
var _enabled_checkbox: CheckBox
var _parameter_rows: Dictionary[StringName, Control] = {}
var _parameter_editors: Dictionary[StringName, Control] = {}


func setup(model: EffectModel) -> void:
	assert(model != null, "EffectModel must not be null")

	_disconnect_model()
	_clear_editors()

	_model = model

	_create_enabled_editor()

	for parameter in _model.parameters:
		_create_parameter_editor(parameter)

	_model.parameter_changed.connect(_on_model_parameter_changed)
	_model.enabled_changed.connect(_on_model_enabled_changed)

	_update_parameter_enabled_states()


func _create_enabled_editor() -> void:
	_enabled_checkbox = CheckBox.new()
	_enabled_checkbox.text = _model.display_name
	_enabled_checkbox.set_pressed_no_signal(_model.enabled)
	_enabled_checkbox.toggled.connect(_on_enabled_checkbox_toggled)

	add_child(_enabled_checkbox)


func _create_parameter_editor(parameter: EffectParameterDefinition) -> void:
	match parameter.kind:
		EffectParameterDefinition.Kind.INTEGER:
			_create_number_editor(parameter, true)

		EffectParameterDefinition.Kind.FLOAT:
			_create_number_editor(parameter, false)

		EffectParameterDefinition.Kind.BOOLEAN:
			_create_boolean_editor(parameter)

		EffectParameterDefinition.Kind.ENUM:
			_create_enum_editor(parameter)

		_:
			assert(false, "Unsupported effect parameter kind: %s" % parameter.kind)


func _create_number_editor(parameter: EffectParameterDefinition, use_integer: bool) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	var spin_box := SpinBox.new()

	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	spin_box.min_value = parameter.min_value
	spin_box.max_value = parameter.max_value
	spin_box.step = parameter.step
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.rounded = use_integer
	spin_box.set_value_no_signal(float(_model.get_value(parameter.id)))
	spin_box.value_changed.connect(_on_number_value_changed.bind(parameter.id))

	row.add_child(label)
	row.add_child(spin_box)
	add_child(row)

	_parameter_rows[parameter.id] = row
	_parameter_editors[parameter.id] = spin_box


func _create_boolean_editor(parameter: EffectParameterDefinition) -> void:
	var checkbox := CheckBox.new()

	checkbox.text = parameter.display_name
	checkbox.set_pressed_no_signal(bool(_model.get_value(parameter.id)))
	checkbox.toggled.connect(_on_boolean_toggled.bind(parameter.id))

	add_child(checkbox)

	_parameter_rows[parameter.id] = checkbox
	_parameter_editors[parameter.id] = checkbox


func _create_enum_editor(parameter: EffectParameterDefinition) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	var option_button := OptionButton.new()

	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for option in parameter.options:
		option_button.add_item(option)

	_select_enum_value(option_button, parameter, int(_model.get_value(parameter.id)))
	option_button.item_selected.connect(_on_enum_item_selected.bind(parameter.id))

	row.add_child(label)
	row.add_child(option_button)
	add_child(row)

	_parameter_rows[parameter.id] = row
	_parameter_editors[parameter.id] = option_button


func _on_enabled_checkbox_toggled(enabled: bool) -> void:
	assert(_model != null, "EffectModel must not be null")
	_model.enabled = enabled


func _on_number_value_changed(value: float, parameter_id: StringName) -> void:
	assert(_model != null, "EffectModel must not be null")
	_model.set_value(parameter_id, value)


func _on_boolean_toggled(value: bool, parameter_id: StringName) -> void:
	assert(_model != null, "EffectModel must not be null")
	_model.set_value(parameter_id, value)


func _on_enum_item_selected(index: int, parameter_id: StringName) -> void:
	assert(_model != null, "EffectModel must not be null")

	var parameter := _model.get_parameter(parameter_id)

	assert(
		index >= 0 and index < parameter.option_values.size(),
		"Invalid enum option index: %s" % index,
	)

	_model.set_value(parameter_id, parameter.option_values[index])


func _on_model_enabled_changed(enabled: bool) -> void:
	if _enabled_checkbox == null:
		return

	_enabled_checkbox.set_pressed_no_signal(enabled)


func _on_model_parameter_changed(id: StringName, value: Variant) -> void:
	_update_editor_value(id, value)
	_update_parameter_enabled_states()


func _update_editor_value(id: StringName, value: Variant) -> void:
	assert(_parameter_editors.has(id), "Parameter editor not found: %s" % id)

	var parameter := _model.get_parameter(id)
	var editor := _parameter_editors[id]

	match parameter.kind:
		EffectParameterDefinition.Kind.INTEGER, EffectParameterDefinition.Kind.FLOAT:
			assert(editor is SpinBox, "Numeric editor must be SpinBox: %s" % id)
			(editor as SpinBox).set_value_no_signal(float(value))

		EffectParameterDefinition.Kind.BOOLEAN:
			assert(editor is CheckBox, "Boolean editor must be CheckBox: %s" % id)
			(editor as CheckBox).set_pressed_no_signal(bool(value))

		EffectParameterDefinition.Kind.ENUM:
			assert(editor is OptionButton, "Enum editor must be OptionButton: %s" % id)
			_select_enum_value(editor as OptionButton, parameter, int(value))

		_:
			assert(false, "Unsupported effect parameter kind: %s" % parameter.kind)


func _select_enum_value(
	option_button: OptionButton,
	parameter: EffectParameterDefinition,
	value: int,
) -> void:
	var option_index := parameter.get_option_index(value)

	assert(
		option_index >= 0,
		"Enum value '%s' was not found: %s" % [value, parameter.id],
	)

	option_button.select(option_index)


func _update_parameter_enabled_states() -> void:
	assert(_model != null, "EffectModel must not be null")

	for parameter in _model.parameters:
		assert(_parameter_rows.has(parameter.id), "Parameter row not found: %s" % parameter.id)
		assert(_parameter_editors.has(parameter.id), "Parameter editor not found: %s" % parameter.id)

		var enabled := _model.is_parameter_enabled(parameter.id)
		var row := _parameter_rows[parameter.id]
		var editor := _parameter_editors[parameter.id]

		_set_editor_enabled(editor, enabled)
		_set_row_enabled_appearance(row, enabled)


func _set_editor_enabled(editor: Control, enabled: bool) -> void:
	if editor is BaseButton:
		(editor as BaseButton).disabled = not enabled
		return

	if editor is SpinBox:
		(editor as SpinBox).editable = enabled
		return

	assert(false, "Unsupported parameter editor: %s" % editor.get_class())


func _set_row_enabled_appearance(row: Control, enabled: bool) -> void:
	var color := row.modulate
	color.a = 1.0 if enabled else 0.5
	row.modulate = color


func _disconnect_model() -> void:
	if _model == null:
		return

	if _model.parameter_changed.is_connected(_on_model_parameter_changed):
		_model.parameter_changed.disconnect(_on_model_parameter_changed)

	if _model.enabled_changed.is_connected(_on_model_enabled_changed):
		_model.enabled_changed.disconnect(_on_model_enabled_changed)

	_model = null


func _clear_editors() -> void:
	_enabled_checkbox = null
	_parameter_rows.clear()
	_parameter_editors.clear()

	for child in get_children():
		remove_child(child)
		child.queue_free()
