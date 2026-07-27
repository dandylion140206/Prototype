@tool
class_name AudioCue
extends Resource

@export var stream: AudioStream
@export var bus: StringName
@export_range(-40.0, 24.0, 0.1) var volume_db: float = 0.0
@export_range(1, 32, 1) var max_polyphony: int = 4
@export_range(0.01, 3.0, 0.01) var initial_pitch: float = 1.0
@export_range(0.0, 1.0, 0.01) var pitch_random_range: float = 0.0
@export_range(0.0, 1.0, 0.01) var pitch_increment: float = 0.0
@export_range(0.01, 3.0, 0.01) var max_pitch: float = 1.0
@export_range(0.0, 5.0, 0.01) var combo_timeout: float = 0.0


func _init() -> void:
	if AudioServer.get_bus_count() > 0:
		bus = StringName(AudioServer.get_bus_name(0))

	if Engine.is_editor_hint():
		AudioServer.bus_layout_changed.connect(_on_bus_layout_changed)


func _validate_property(property: Dictionary) -> void:
	if property.name != &"bus":
		return

	var bus_names := PackedStringArray()
	for bus_index in AudioServer.get_bus_count():
		bus_names.append(AudioServer.get_bus_name(bus_index))

	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(bus_names)


func _on_bus_layout_changed() -> void:
	notify_property_list_changed()
