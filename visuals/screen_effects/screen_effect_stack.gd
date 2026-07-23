class_name ScreenEffectStack
extends Node

signal enabled_changed(enabled: bool)
signal preset_changed(preset_name: String)
signal preset_dirty_changed(is_dirty: bool)
signal settings_changed

@export var enabled_by_default: bool = true

var enabled: bool = true:
	set(value):
		if enabled == value:
			return

		enabled = value
		_set_stages_visible(enabled)
		enabled_changed.emit(enabled)

var _preset_store: ScreenEffectPresetStore
var _active_preset_name: String = ScreenEffectPresetStore.DEFAULT_PRESET_NAME
var _saved_settings: Dictionary = {}
var _is_preset_dirty: bool = false
var _is_applying_settings: bool = false


func _ready() -> void:
	for effect_pass in _get_effect_passes():
		assert(
			effect_pass.state != null,
			"Screen effect state must be initialized: %s" % effect_pass.name
		)

	_connect_effect_states()

	_preset_store = ScreenEffectPresetStore.new()
	_active_preset_name = _preset_store.get_active_preset_name()

	if (
		_active_preset_name != ScreenEffectPresetStore.DEFAULT_PRESET_NAME
		and not _preset_store.has_preset(_active_preset_name)
	):
		_active_preset_name = ScreenEffectPresetStore.DEFAULT_PRESET_NAME

	_apply_preset(_active_preset_name)


func get_states() -> Array[ScreenEffectState]:
	var states: Array[ScreenEffectState] = []

	for effect_pass in _get_effect_passes():
		assert(
			effect_pass.state != null,
			"Screen effect state must be initialized: %s" % effect_pass.name
		)
		states.append(effect_pass.state)

	return states


func get_preset_names() -> Array[String]:
	assert(_preset_store != null, "ScreenEffectPresetStore must be initialized")

	var preset_names: Array[String] = [ScreenEffectPresetStore.DEFAULT_PRESET_NAME]
	preset_names.append_array(_preset_store.get_preset_names())

	return preset_names


func get_active_preset_name() -> String:
	return _active_preset_name


func is_preset_dirty() -> bool:
	return _is_preset_dirty


func select_preset(preset_name: String) -> Error:
	assert(_preset_store != null, "ScreenEffectPresetStore must be initialized")

	if (
		preset_name != ScreenEffectPresetStore.DEFAULT_PRESET_NAME
		and not _preset_store.has_preset(preset_name)
	):
		return ERR_DOES_NOT_EXIST

	var error := _preset_store.set_active_preset_name(preset_name)

	if error != OK:
		return error

	_active_preset_name = preset_name
	_apply_preset(_active_preset_name)
	preset_changed.emit(_active_preset_name)

	return OK


func save_active_preset() -> Error:
	if _active_preset_name == ScreenEffectPresetStore.DEFAULT_PRESET_NAME:
		return ERR_UNAVAILABLE

	return _save_preset(_active_preset_name)


func save_as_preset(preset_name: String) -> Error:
	assert(_preset_store != null, "ScreenEffectPresetStore must be initialized")

	if not ScreenEffectPresetStore.is_valid_preset_name(preset_name):
		return ERR_INVALID_PARAMETER

	var normalized_preset_name := preset_name.strip_edges()
	var error := _save_preset(normalized_preset_name)

	if error != OK:
		return error

	_active_preset_name = normalized_preset_name
	preset_changed.emit(_active_preset_name)

	return OK


func delete_active_preset() -> Error:
	if _active_preset_name == ScreenEffectPresetStore.DEFAULT_PRESET_NAME:
		return ERR_UNAVAILABLE

	var error := _preset_store.delete_preset(_active_preset_name)

	if error != OK:
		return error

	_active_preset_name = ScreenEffectPresetStore.DEFAULT_PRESET_NAME
	_apply_preset(_active_preset_name)
	preset_changed.emit(_active_preset_name)

	return OK


func reset_all() -> void:
	_is_applying_settings = true
	enabled = enabled_by_default

	for state in get_states():
		state.reset()

	_is_applying_settings = false
	_update_preset_dirty_state()
	settings_changed.emit()


func create_settings() -> Dictionary:
	var effect_settings := {}

	for state in get_states():
		effect_settings[String(state.id)] = state.create_settings()

	return {
		"enabled": enabled,
		"effects": effect_settings,
	}


func _on_effect_state_changed(_id: StringName, _value: Variant) -> void:
	_on_settings_changed()


func _on_effect_state_enabled_changed(_enabled: bool) -> void:
	_on_settings_changed()


func _on_stack_enabled_changed(_enabled: bool) -> void:
	_on_settings_changed()


func _on_settings_changed() -> void:
	if _is_applying_settings:
		return

	_update_preset_dirty_state()
	settings_changed.emit()


func _get_effect_passes() -> Array[ScreenEffectPass]:
	var effect_passes: Array[ScreenEffectPass] = []

	for stage in _get_effect_stages():
		for child in stage.get_children():
			assert(child is ScreenEffectPass, "Screen effect stages must contain ScreenEffectPass nodes")
			effect_passes.append(child as ScreenEffectPass)

	return effect_passes


func _get_effect_stages() -> Array[CanvasLayer]:
	var stages: Array[CanvasLayer] = []

	for child in get_children():
		assert(child is CanvasLayer, "ScreenEffectStack children must be CanvasLayer nodes")
		stages.append(child as CanvasLayer)

	return stages


func _set_stages_visible(is_visible: bool) -> void:
	for stage in _get_effect_stages():
		stage.visible = is_visible


func _connect_effect_states() -> void:
	var effect_ids: Dictionary[StringName, bool] = {}

	for state in get_states():
		assert(not effect_ids.has(state.id), "Duplicate screen effect id: %s" % state.id)

		effect_ids[state.id] = true
		state.parameter_changed.connect(_on_effect_state_changed)
		state.enabled_changed.connect(_on_effect_state_enabled_changed)

	enabled_changed.connect(_on_stack_enabled_changed)


func _apply_preset(preset_name: String) -> void:
	_is_applying_settings = true
	enabled = enabled_by_default

	for state in get_states():
		state.reset()

	if preset_name != ScreenEffectPresetStore.DEFAULT_PRESET_NAME:
		_apply_settings(_preset_store.load_preset(preset_name))

	_is_applying_settings = false
	_saved_settings = create_settings()
	_update_preset_dirty_state()
	settings_changed.emit()


func _apply_settings(settings: Dictionary) -> void:
	if settings.has("enabled"):
		enabled = bool(settings["enabled"])

	var effect_settings_value: Variant = settings.get("effects", {})
	if not effect_settings_value is Dictionary:
		push_warning("Invalid screen effect preset settings")
		return

	var effect_settings: Dictionary = effect_settings_value

	for state in get_states():
		var effect_id := String(state.id)

		if not effect_settings.has(effect_id):
			continue

		var state_settings: Variant = effect_settings[effect_id]

		if state_settings is Dictionary:
			state.apply_settings(state_settings)


func _save_preset(preset_name: String) -> Error:
	var error := _preset_store.save_preset(preset_name, create_settings())

	if error != OK:
		return error

	_saved_settings = create_settings()
	_update_preset_dirty_state()

	return OK


func _update_preset_dirty_state() -> void:
	var is_dirty := create_settings() != _saved_settings

	if _is_preset_dirty == is_dirty:
		return

	_is_preset_dirty = is_dirty
	preset_dirty_changed.emit(_is_preset_dirty)
