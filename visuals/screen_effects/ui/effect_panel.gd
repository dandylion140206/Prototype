class_name EffectPanel
extends VBoxContainer

@export var effect_path: NodePath


func _ready() -> void:
	var effect := get_node(effect_path)
	var model: EffectModel = effect.get_effect_model()
	setup(model)


func setup(model: EffectModel) -> void:
	_clear()

	var enabled_checkbox := CheckBox.new()
	enabled_checkbox.text = model.display_name
	enabled_checkbox.button_pressed = model.enabled
	enabled_checkbox.toggled.connect(
		func(enabled: bool) -> void:
			model.enabled = enabled
	)
	add_child(enabled_checkbox)

	for parameter in model.parameters:
		_create_parameter_editor(model, parameter)


func _create_parameter_editor(
	model: EffectModel,
	parameter: EffectParameter,
) -> void:
	match parameter.kind:
		EffectParameter.Kind.INTEGER:
			_create_number_editor(model, parameter, true)
		EffectParameter.Kind.FLOAT:
			_create_number_editor(model, parameter, false)
		EffectParameter.Kind.BOOLEAN:
			_create_boolean_editor(model, parameter)


func _create_number_editor(
	model: EffectModel,
	parameter: EffectParameter,
	use_integer: bool,
) -> void:
	var parameter_container := VBoxContainer.new()
	var header_row := HBoxContainer.new()
	var label := Label.new()
	var spin_box := SpinBox.new()
	var slider := HSlider.new()
	var line_edit := spin_box.get_line_edit()

	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	spin_box.custom_minimum_size.x = 96.0
	spin_box.min_value = parameter.min_value
	spin_box.max_value = parameter.max_value
	spin_box.step = parameter.step
	spin_box.value = float(model.get_value(parameter.id))

	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.text_submitted.connect(
		func(_text: String) -> void:
			line_edit.release_focus()
	)

	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = parameter.min_value
	slider.max_value = parameter.max_value
	slider.step = parameter.step
	slider.value = spin_box.value

	spin_box.value_changed.connect(
		func(value: float) -> void:
			slider.set_value_no_signal(value)
			_set_number_value(model, parameter.id, value, use_integer)
	)

	slider.value_changed.connect(
		func(value: float) -> void:
			spin_box.set_value_no_signal(value)
			_set_number_value(model, parameter.id, value, use_integer)
	)

	header_row.add_child(label)
	header_row.add_child(spin_box)
	parameter_container.add_child(header_row)
	parameter_container.add_child(slider)
	add_child(parameter_container)


func _set_number_value(
	model: EffectModel,
	id: StringName,
	value: float,
	use_integer: bool,
) -> void:
	var result: Variant = int(value) if use_integer else value
	model.set_value(id, result)


func _create_boolean_editor(
	model: EffectModel,
	parameter: EffectParameter,
) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = parameter.display_name
	checkbox.button_pressed = bool(model.get_value(parameter.id))
	checkbox.toggled.connect(
		func(value: bool) -> void:
			model.set_value(parameter.id, value)
	)
	add_child(checkbox)


func _clear() -> void:
	for child in get_children():
		child.queue_free()
