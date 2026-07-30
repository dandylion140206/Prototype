@tool
class_name AudioCue
extends Resource

enum OverflowPolicy {
	STEAL_OLDEST,
	DROP_NEW,
}

enum AggregationMode {
	NONE,
	BY_SOURCE,
}

@export_group("Audio")
@export var stream: AudioStream
@export var bus: StringName = &"SFX"
@export_range(-16.0, 16.0, 0.1) var volume_db: float = 0.0

@export_group("Pitch")
@export_range(0.01, 3.0, 0.01) var base_pitch: float = 1.0
@export_range(0.0, 1.0, 0.01) var random_pitch_range: float = 0.0
@export_range(0.0, 1.0, 0.01) var sequence_pitch_step: float = 0.0
@export_range(0.0, 3.0, 0.01) var max_sequence_pitch_offset: float = 0.0

@export_group("Concurrency")
@export_range(1, 32, 1) var max_concurrent_playbacks: int = 4
@export var overflow_policy: OverflowPolicy = OverflowPolicy.STEAL_OLDEST
@export_range(0.0, 1.0, 0.01) var minimum_interval: float = 0.0

@export_group("Aggregation")
@export var aggregation_mode: AggregationMode = AggregationMode.NONE
@export_range(0.0, 0.2, 0.005) var aggregation_window: float = 0.0


func _init() -> void:
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
