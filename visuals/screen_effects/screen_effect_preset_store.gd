class_name ScreenEffectPresetStore
extends RefCounted

const FILE_PATH := "user://screen_effect_presets.cfg"
const SETTINGS_SECTION := "settings"
const ACTIVE_PRESET_KEY := "active_preset"
const PRESET_SECTION_PREFIX := "preset/"
const DEFAULT_PRESET_NAME := "Default"

var _config: ConfigFile = ConfigFile.new()


func _init() -> void:
	var error := _config.load(FILE_PATH)

	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("Failed to load screen effect presets: %s" % error)


func get_active_preset_name() -> String:
	return String(_config.get_value(SETTINGS_SECTION, ACTIVE_PRESET_KEY, DEFAULT_PRESET_NAME))


func get_preset_names() -> Array[String]:
	var preset_names: Array[String] = []

	for section in _config.get_sections():
		if not section.begins_with(PRESET_SECTION_PREFIX):
			continue

		var preset_name := section.trim_prefix(PRESET_SECTION_PREFIX)
		if preset_name == DEFAULT_PRESET_NAME:
			continue

		preset_names.append(preset_name)

	preset_names.sort()
	return preset_names


func has_preset(preset_name: String) -> bool:
	return _config.has_section(_get_preset_section(preset_name))


func load_preset(preset_name: String) -> Dictionary:
	var settings: Variant = _config.get_value(
		_get_preset_section(preset_name),
		"settings",
		{},
	)

	if settings is Dictionary:
		return settings

	push_warning("Invalid screen effect preset: %s" % preset_name)
	return {}


func save_preset(preset_name: String, settings: Dictionary) -> Error:
	if not is_valid_preset_name(preset_name):
		return ERR_INVALID_PARAMETER

	var normalized_preset_name := preset_name.strip_edges()
	var staged_config := _create_staged_config()
	staged_config.set_value(_get_preset_section(normalized_preset_name), "settings", settings)
	staged_config.set_value(SETTINGS_SECTION, ACTIVE_PRESET_KEY, normalized_preset_name)

	return _commit_staged_config(staged_config)


func set_active_preset_name(preset_name: String) -> Error:
	var staged_config := _create_staged_config()
	staged_config.set_value(SETTINGS_SECTION, ACTIVE_PRESET_KEY, preset_name)

	return _commit_staged_config(staged_config)


func delete_preset(preset_name: String) -> Error:
	var staged_config := _create_staged_config()
	staged_config.erase_section(_get_preset_section(preset_name))

	if get_active_preset_name() == preset_name:
		staged_config.set_value(SETTINGS_SECTION, ACTIVE_PRESET_KEY, DEFAULT_PRESET_NAME)

	return _commit_staged_config(staged_config)


static func is_valid_preset_name(preset_name: String) -> bool:
	var normalized_preset_name := preset_name.strip_edges()

	return (
		not normalized_preset_name.is_empty()
		and normalized_preset_name != DEFAULT_PRESET_NAME
		and not preset_name.contains("/")
		and not preset_name.contains("\n")
	)


func _get_preset_section(preset_name: String) -> String:
	return PRESET_SECTION_PREFIX + preset_name


func _create_staged_config() -> ConfigFile:
	var staged_config := ConfigFile.new()
	var config_text := _config.encode_to_text()

	if config_text.is_empty():
		return staged_config

	var error := staged_config.parse(config_text)
	assert(error == OK, "Failed to stage screen effect presets: %s" % error)

	return staged_config


func _commit_staged_config(staged_config: ConfigFile) -> Error:
	var error := staged_config.save(FILE_PATH)

	if error == OK:
		_config = staged_config

	return error
