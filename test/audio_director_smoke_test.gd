extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_initial_pool_and_expansion()
	_test_drop_new()
	_test_steal_oldest()
	_test_steal_does_not_affect_other_cues()
	await _test_aggregation()
	_test_minimum_interval()
	_test_sequence_pitch()
	_test_boost_has_no_direct_player()
	for _frame_index in 10:
		await process_frame

	print("AudioDirector smoke test passed.")
	quit.call_deferred()


func _test_initial_pool_and_expansion() -> void:
	var audio_director := _create_audio_director(16)
	assert(audio_director.get_child_count() == 16, "The initial pool must contain 16 players.")

	var cue := _create_audio_cue()
	cue.max_concurrent_playbacks = 32
	for request_index in 17:
		audio_director.request(
			AudioRequest.new(cue, Vector2(request_index, 0.0), request_index + 1)
		)

	assert(audio_director.get_child_count() == 17, "The pool must expand without a global cap.")
	audio_director.free()


func _test_drop_new() -> void:
	var audio_director := _create_audio_director(1)
	var cue := _create_audio_cue()
	cue.max_concurrent_playbacks = 1
	cue.overflow_policy = AudioCue.OverflowPolicy.DROP_NEW

	audio_director.request(AudioRequest.new(cue, Vector2(10.0, 20.0), 1))
	audio_director.request(AudioRequest.new(cue, Vector2(30.0, 40.0), 2))

	var players := _get_players_for_stream(audio_director, cue.stream)
	assert(players.size() == 1, "DROP_NEW must keep one playback.")
	assert(
		players[0].global_position == Vector2(10.0, 20.0),
		"DROP_NEW must preserve the existing playback."
	)
	audio_director.free()


func _test_steal_oldest() -> void:
	var audio_director := _create_audio_director(1)
	var cue := _create_audio_cue()
	cue.max_concurrent_playbacks = 1
	cue.overflow_policy = AudioCue.OverflowPolicy.STEAL_OLDEST

	audio_director.request(AudioRequest.new(cue, Vector2(10.0, 20.0), 1))
	audio_director.request(AudioRequest.new(cue, Vector2(30.0, 40.0), 2))

	var players := _get_players_for_stream(audio_director, cue.stream)
	assert(players.size() == 1, "STEAL_OLDEST must reuse the Cue playback.")
	assert(
		players[0].global_position == Vector2(30.0, 40.0),
		"STEAL_OLDEST must replace the oldest playback."
	)
	audio_director.free()


func _test_steal_does_not_affect_other_cues() -> void:
	var audio_director := _create_audio_director(2)
	var first_cue := _create_audio_cue()
	first_cue.max_concurrent_playbacks = 1
	first_cue.overflow_policy = AudioCue.OverflowPolicy.STEAL_OLDEST
	var second_cue := _create_audio_cue(
		"res://test/USER_INTERFACE_Light_On_Click_02.mp3"
	)
	second_cue.max_concurrent_playbacks = 1

	audio_director.request(AudioRequest.new(first_cue, Vector2(10.0, 0.0), 1))
	audio_director.request(AudioRequest.new(second_cue, Vector2(20.0, 0.0), 2))
	audio_director.request(AudioRequest.new(first_cue, Vector2(30.0, 0.0), 3))

	var second_players := _get_players_for_stream(audio_director, second_cue.stream)
	assert(second_players.size() == 1, "Stealing one Cue must not stop another Cue.")
	assert(
		second_players[0].global_position == Vector2(20.0, 0.0),
		"The unrelated Cue playback must remain unchanged."
	)
	audio_director.free()


func _test_aggregation() -> void:
	var audio_director := _create_audio_director(1)
	var cue := _create_audio_cue()
	cue.max_concurrent_playbacks = 4
	cue.aggregation_mode = AudioCue.AggregationMode.BY_SOURCE
	cue.aggregation_window = 0.0
	cue.sequence_pitch_step = 0.15
	cue.max_sequence_pitch_offset = 1.0

	audio_director.request(AudioRequest.new(cue, Vector2(10.0, 20.0), 1, 0))
	audio_director.request(AudioRequest.new(cue, Vector2(30.0, 40.0), 1, 2))
	assert(
		_get_players_for_stream(audio_director, cue.stream).is_empty(),
		"Aggregated requests must wait until the next process step."
	)

	await process_frame
	await process_frame

	var players := _get_players_for_stream(audio_director, cue.stream)
	assert(players.size() == 1, "Requests with the same Cue and source must aggregate.")
	assert(
		players[0].global_position == Vector2(20.0, 30.0),
		"Aggregated playback must use the arithmetic mean position."
	)
	assert(
		is_equal_approx(players[0].pitch_scale, 1.3),
		"Aggregated playback must use the maximum sequence index."
	)

	var distinct_cue := _create_audio_cue(
		"res://test/USER_INTERFACE_Light_On_Click_02.mp3"
	)
	distinct_cue.max_concurrent_playbacks = 4
	distinct_cue.aggregation_mode = AudioCue.AggregationMode.BY_SOURCE
	distinct_cue.aggregation_window = 0.0
	audio_director.request(AudioRequest.new(distinct_cue, Vector2(10.0, 20.0), 1))
	audio_director.request(AudioRequest.new(distinct_cue, Vector2(30.0, 40.0), 2))

	await process_frame
	await process_frame

	players = _get_players_for_stream(audio_director, distinct_cue.stream)
	assert(players.size() == 2, "Different source IDs must form separate aggregations.")
	audio_director.free()
	await process_frame


func _test_minimum_interval() -> void:
	var audio_director := _create_audio_director(1)
	var cue := _create_audio_cue()
	cue.max_concurrent_playbacks = 4
	cue.minimum_interval = 1.0

	audio_director.request(AudioRequest.new(cue, Vector2(10.0, 20.0), 1))
	audio_director.request(AudioRequest.new(cue, Vector2(30.0, 40.0), 2))

	var players := _get_players_for_stream(audio_director, cue.stream)
	assert(players.size() == 1, "The minimum interval must drop an early request.")
	audio_director.free()


func _test_sequence_pitch() -> void:
	var audio_director := _create_audio_director(1)
	var cue := _create_audio_cue()
	cue.sequence_pitch_step = 0.15
	cue.max_sequence_pitch_offset = 0.6

	audio_director.request(AudioRequest.new(cue, Vector2.ZERO, 1, 10))

	var players := _get_players_for_stream(audio_director, cue.stream)
	assert(players.size() == 1, "A sequence pitch request must play.")
	assert(
		is_equal_approx(players[0].pitch_scale, 1.6),
		"Sequence pitch must not exceed the configured maximum offset."
	)
	audio_director.free()


func _test_boost_has_no_direct_player() -> void:
	var boost_scene := load("res://game/ball/abilities/boost/boost.tscn") as PackedScene
	assert(boost_scene != null, "Boost Scene must load.")

	var boost := boost_scene.instantiate()
	assert(
		boost.find_children("*", "AudioStreamPlayer2D", true, false).is_empty(),
		"Boost Scene must not contain a direct AudioStreamPlayer2D."
	)
	boost.free()


func _create_audio_director(initial_pool_size: int) -> AudioDirector:
	var audio_director := AudioDirector.new()
	audio_director.initial_pool_size = initial_pool_size
	root.add_child(audio_director)
	return audio_director


func _create_audio_cue(
	stream_path: String = "res://test/USER_INTERFACE_Error_03.mp3"
) -> AudioCue:
	var cue := AudioCue.new()
	cue.stream = load(stream_path) as AudioStream
	cue.bus = &"SFX"
	return cue


func _get_players_for_stream(
	audio_director: AudioDirector,
	stream: AudioStream
) -> Array[AudioStreamPlayer2D]:
	var players: Array[AudioStreamPlayer2D] = []

	for child in audio_director.get_children():
		var player := child as AudioStreamPlayer2D
		if player != null and player.stream == stream and player.playing:
			players.append(player)

	return players
