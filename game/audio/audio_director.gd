class_name AudioDirector
extends Node

const USEC_PER_SECOND: float = 1_000_000.0

@export_range(1, 64, 1) var initial_pool_size: int = 16

var _playback_slots: Array[PlaybackSlot] = []
var _last_started_at_by_cue_id: Dictionary[int, int] = {}
var _pending_aggregations: Dictionary[String, PendingAggregation] = {}


func _ready() -> void:
	assert(initial_pool_size > 0, "initial_pool_size must be positive.")

	for _slot_index in initial_pool_size:
		_create_playback_slot()


func _process(_delta: float) -> void:
	if _pending_aggregations.is_empty():
		return

	var current_time_usec := Time.get_ticks_usec()
	var ready_keys: Array[String] = []

	for aggregation_key in _pending_aggregations:
		var aggregation := _pending_aggregations[aggregation_key]
		if current_time_usec - aggregation.first_requested_at_usec >= aggregation.window_usec:
			ready_keys.append(aggregation_key)

	for aggregation_key in ready_keys:
		var aggregation := _pending_aggregations[aggregation_key]
		_pending_aggregations.erase(aggregation_key)
		_try_play(aggregation.create_request(), current_time_usec)


func _exit_tree() -> void:
	_pending_aggregations.clear()
	_last_started_at_by_cue_id.clear()

	for slot in _playback_slots:
		_disconnect_finished_callback(slot)
		slot.player.stop()
		slot.cue = null
		slot.is_active = false

	_playback_slots.clear()


func request(audio_request: AudioRequest) -> void:
	assert(audio_request != null, "audio_request must not be null.")
	assert(audio_request.cue != null, "audio_request.cue must not be null.")
	assert(audio_request.cue.stream != null, "audio_request.cue.stream must not be null.")
	assert(
		audio_request.cue.max_concurrent_playbacks > 0,
		"audio_request.cue.max_concurrent_playbacks must be positive."
	)
	assert(
		audio_request.cue.minimum_interval >= 0.0,
		"audio_request.cue.minimum_interval must not be negative."
	)
	assert(
		audio_request.cue.aggregation_window >= 0.0,
		"audio_request.cue.aggregation_window must not be negative."
	)
	assert(
		AudioServer.get_bus_index(audio_request.cue.bus) >= 0,
		"audio_request.cue.bus must reference an existing audio bus."
	)

	if audio_request.cue.aggregation_mode == AudioCue.AggregationMode.BY_SOURCE:
		_queue_aggregation(audio_request)
		return

	_try_play(audio_request, Time.get_ticks_usec())


func _queue_aggregation(audio_request: AudioRequest) -> void:
	var aggregation_key := _create_aggregation_key(audio_request)
	var aggregation := _pending_aggregations.get(aggregation_key) as PendingAggregation

	if aggregation == null:
		var window_usec := int(audio_request.cue.aggregation_window * USEC_PER_SECOND)
		aggregation = PendingAggregation.new(audio_request, Time.get_ticks_usec(), window_usec)
		_pending_aggregations[aggregation_key] = aggregation
		return

	aggregation.add_request(audio_request)


func _create_aggregation_key(audio_request: AudioRequest) -> String:
	return "%d:%d" % [audio_request.cue.get_instance_id(), audio_request.source_id]


func _try_play(audio_request: AudioRequest, current_time_usec: int) -> void:
	var cue := audio_request.cue
	var cue_id := cue.get_instance_id()
	var minimum_interval_usec := int(cue.minimum_interval * USEC_PER_SECOND)
	var last_started_at_usec := int(
		_last_started_at_by_cue_id.get(cue_id, -minimum_interval_usec)
	)

	if current_time_usec - last_started_at_usec < minimum_interval_usec:
		return

	var active_count := 0
	var oldest_slot: PlaybackSlot = null

	for slot in _playback_slots:
		if not slot.is_active or slot.cue.get_instance_id() != cue_id:
			continue

		active_count += 1
		if oldest_slot == null or slot.started_at_usec < oldest_slot.started_at_usec:
			oldest_slot = slot

	var target_slot: PlaybackSlot = null
	if active_count >= cue.max_concurrent_playbacks:
		if cue.overflow_policy == AudioCue.OverflowPolicy.DROP_NEW:
			return

		target_slot = oldest_slot
	else:
		target_slot = _find_unused_slot()

	if target_slot == null:
		target_slot = _create_playback_slot()

	_start_playback(target_slot, audio_request, current_time_usec)
	_last_started_at_by_cue_id[cue_id] = current_time_usec


func _find_unused_slot() -> PlaybackSlot:
	for slot in _playback_slots:
		if not slot.is_active:
			return slot

	return null


func _create_playback_slot() -> PlaybackSlot:
	var player := AudioStreamPlayer2D.new()
	player.name = "AudioPlayer%d" % (_playback_slots.size() + 1)
	player.max_polyphony = 1
	add_child(player)

	var slot := PlaybackSlot.new(player)
	_playback_slots.append(slot)
	return slot


func _start_playback(
	slot: PlaybackSlot,
	audio_request: AudioRequest,
	current_time_usec: int
) -> void:
	_disconnect_finished_callback(slot)
	slot.player.stop()
	slot.playback_generation += 1

	var playback_generation := slot.playback_generation
	slot.finished_callback = _on_player_finished.bind(slot, playback_generation)
	slot.player.finished.connect(slot.finished_callback, CONNECT_ONE_SHOT)

	slot.cue = audio_request.cue
	slot.started_at_usec = current_time_usec
	slot.is_active = true

	slot.player.stream = audio_request.cue.stream
	slot.player.bus = audio_request.cue.bus
	slot.player.volume_db = audio_request.cue.volume_db
	slot.player.pitch_scale = _calculate_pitch(audio_request)
	slot.player.global_position = audio_request.world_position
	slot.player.play()


func _disconnect_finished_callback(slot: PlaybackSlot) -> void:
	if slot.finished_callback.is_valid() and slot.player.finished.is_connected(
		slot.finished_callback
	):
		slot.player.finished.disconnect(slot.finished_callback)

	slot.finished_callback = Callable()


func _on_player_finished(slot: PlaybackSlot, playback_generation: int) -> void:
	if slot.playback_generation != playback_generation:
		return

	slot.cue = null
	slot.started_at_usec = 0
	slot.is_active = false
	slot.finished_callback = Callable()


func _calculate_pitch(audio_request: AudioRequest) -> float:
	var cue := audio_request.cue
	var sequence_offset := minf(
		cue.sequence_pitch_step * audio_request.sequence_index,
		cue.max_sequence_pitch_offset
	)
	var random_offset := randf_range(-cue.random_pitch_range, cue.random_pitch_range)
	return maxf(cue.base_pitch + sequence_offset + random_offset, 0.01)


class PlaybackSlot:
	var player: AudioStreamPlayer2D
	var cue: AudioCue
	var started_at_usec: int = 0
	var is_active: bool = false
	var playback_generation: int = 0
	var finished_callback: Callable


	func _init(p_player: AudioStreamPlayer2D) -> void:
		player = p_player


class PendingAggregation:
	var cue: AudioCue
	var source_id: int
	var position_sum: Vector2
	var request_count: int
	var max_sequence_index: int
	var first_requested_at_usec: int
	var window_usec: int


	func _init(audio_request: AudioRequest, requested_at_usec: int, p_window_usec: int) -> void:
		cue = audio_request.cue
		source_id = audio_request.source_id
		position_sum = audio_request.world_position
		request_count = 1
		max_sequence_index = audio_request.sequence_index
		first_requested_at_usec = requested_at_usec
		window_usec = p_window_usec


	func add_request(audio_request: AudioRequest) -> void:
		position_sum += audio_request.world_position
		request_count += 1
		max_sequence_index = maxi(max_sequence_index, audio_request.sequence_index)


	func create_request() -> AudioRequest:
		var average_position := position_sum / request_count
		return AudioRequest.new(cue, average_position, source_id, max_sequence_index)
