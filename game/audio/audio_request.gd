class_name AudioRequest
extends RefCounted

var cue: AudioCue
var world_position: Vector2
var source_id: int
var sequence_index: int


func _init(
	p_cue: AudioCue,
	p_world_position: Vector2,
	p_source_id: int,
	p_sequence_index: int = 0
) -> void:
	assert(p_cue != null, "p_cue must not be null.")
	assert(p_source_id > 0, "p_source_id must be positive.")
	assert(p_sequence_index >= 0, "p_sequence_index must not be negative.")

	cue = p_cue
	world_position = p_world_position
	source_id = p_source_id
	sequence_index = p_sequence_index
