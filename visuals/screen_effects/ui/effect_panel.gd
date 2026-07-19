class_name EffectPanel
extends VBoxContainer


@export var effect_path: NodePath


func _ready() -> void:
	var effect := get_node(effect_path)
	var model: EffectModel = effect.get_effect_model()

	setup(model)


func setup(model: EffectModel) -> void:
	_clear()

	var title := Label.new()
	title.text = model.display_name
	add_child(title)

	var enabled_checkbox := CheckBox.new()
	enabled_checkbox.text = "有効"
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
	var row := HBoxContainer.new()
	add_child(row)

	var label := Label.new()
	label.text = parameter.display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var spin_box := SpinBox.new()
	spin_box.min_value = parameter.min_value
	spin_box.max_value = parameter.max_value
	spin_box.step = parameter.step
	spin_box.value = float(model.get_value(parameter.id))
	row.add_child(spin_box)

	spin_box.value_changed.connect(
		func(value: float) -> void:
			if use_integer:
				model.set_value(parameter.id, int(value))
			else:
				model.set_value(parameter.id, value)
	)


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
