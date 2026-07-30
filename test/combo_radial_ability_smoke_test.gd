extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	assert(InputMap.has_action("secondary_action"), "secondary_action must exist.")
	assert(not InputMap.has_action("secondry_action"), "secondry_action must be removed.")

	var has_right_mouse_binding := false
	for input_event in InputMap.action_get_events("secondary_action"):
		var mouse_button_event := input_event as InputEventMouseButton
		if mouse_button_event != null and mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			has_right_mouse_binding = true
			break

	assert(has_right_mouse_binding, "secondary_action must be bound to the right mouse button.")

	var test_scene := load("res://test/Test.tscn") as PackedScene
	assert(test_scene != null, "Test.tscn must load.")

	var test_instance := test_scene.instantiate()
	root.add_child(test_instance)

	var ball := test_instance.get_node("Gameplay/Ball") as Ball
	var scene_ability := test_instance.get_node("Gameplay/ComboRadialAbility") as ComboRadialAbility
	var combo_label := test_instance.get_node("WorldUI/ComboLabel") as Label
	var audio_director := test_instance.get_node("AudioDirector") as AudioDirector
	assert(ball != null, "Ball must exist.")
	assert(scene_ability != null, "ComboRadialAbility must exist.")
	assert(combo_label != null, "ComboLabel must exist under WorldUI.")
	assert(audio_director != null, "AudioDirector must exist.")
	assert(audio_director.get_child_count() == 16, "AudioDirector must create its initial pool.")

	var audio_test_hit := HitData.new(
		1.0,
		Vector2.RIGHT,
		ball.global_position,
		0,
		0,
		ball.get_instance_id()
	)
	var ball_audio_requests: Array[AudioRequest] = []
	var combo_audio_requests: Array[AudioRequest] = []
	ball.audio_requested.connect(
		func(audio_request: AudioRequest) -> void: ball_audio_requests.append(audio_request)
	)
	scene_ability.audio_requested.connect(
		func(audio_request: AudioRequest) -> void: combo_audio_requests.append(audio_request)
	)
	ball._handle_landed_hits([audio_test_hit])
	assert(ball_audio_requests.size() == 1, "Ball must request one normal hit sound.")
	assert(
		ball_audio_requests[0].cue == ball.hit_audio_cue,
		"Ball must own the normal hit audio cue."
	)
	assert(combo_audio_requests.size() == 1, "A registered Ball hit must request combo audio.")
	assert(
		combo_audio_requests[0].cue == scene_ability.combo_hit_audio_cue,
		"ComboRadialAbility must own the combo audio cue."
	)
	assert(combo_audio_requests[0].sequence_index == 0, "The first combo sequence index must be zero.")
	assert(
		combo_audio_requests[0].source_id == audio_test_hit.attack_source_id,
		"Combo audio must preserve the attack source ID."
	)

	test_instance.free()

	var test_world := Node2D.new()
	root.add_child(test_world)

	var attack_source := Node2D.new()
	attack_source.global_position = Vector2(100.0, 100.0)
	test_world.add_child(attack_source)

	var ability := ComboRadialAbility.new()

	var cooldown_timer := Timer.new()
	cooldown_timer.name = "CooldownTimer"
	ability.add_child(cooldown_timer)

	var attack_visual := RadialAttackVisual.new()
	attack_visual.name = "RadialAttackVisual"
	ability.add_child(attack_visual)

	ability.radial_activation_audio_cue = load(
		"res://test/radial_activation_audio_cue.tres"
	) as AudioCue
	ability.radial_hit_audio_cue = load("res://test/radial_hit_audio_cue.tres") as AudioCue
	ability.combo_hit_audio_cue = load("res://test/combo_hit_audio_cue.tres") as AudioCue
	test_world.add_child(ability)
	ability.setup(attack_source)

	var ability_audio_requests: Array[AudioRequest] = []
	ability.audio_requested.connect(
		func(audio_request: AudioRequest) -> void: ability_audio_requests.append(audio_request)
	)

	var combo_hit := _create_hit_data(attack_source)
	ability.register_ball_hit(combo_hit)
	ability.register_ball_hit(combo_hit)
	assert(ability.get_combo_count() == 1, "Multiple hits in one physics frame must add one combo.")

	await physics_frame
	ability.register_ball_hit(combo_hit)
	assert(ability.get_combo_count() == 2, "A hit in the next physics frame must add one combo.")

	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 0
	hurtbox.global_position = attack_source.global_position + Vector2(45.0, 0.0)

	var collision_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 8.0
	collision_shape.shape = circle_shape
	collision_shape.name = "CollisionShape2D"
	hurtbox.add_child(collision_shape)
	test_world.add_child(hurtbox)

	var received_hits: Array[HitData] = []
	hurtbox.hit_received.connect(func(hit_data: HitData) -> void: received_hits.append(hit_data))

	await physics_frame

	var preceding_ball_hit := HitData.new(
		1.0,
		Vector2.RIGHT,
		hurtbox.global_position,
		0,
		0,
		attack_source.get_instance_id()
	)
	assert(hurtbox.receive_hit(preceding_ball_hit), "The preceding Ball hit must be accepted.")
	received_hits.clear()

	assert(ability.try_activate(), "Ability must activate when cooldown is ready.")
	assert(received_hits.is_empty(), "The expanding attack must not hit the target immediately.")
	assert(ability.get_combo_count() == 0, "Ability activation must consume the combo.")
	assert(not ability.try_activate(), "Ability must not activate during cooldown.")
	var activation_requests := _get_requests_for_cue(
		ability_audio_requests,
		ability.radial_activation_audio_cue
	)
	assert(activation_requests.size() == 1, "Ability activation must request one sound.")

	for _frame_index in 20:
		if not received_hits.is_empty():
			break

		await physics_frame

	assert(received_hits.size() == 1, "The expanding attack must hit the hurtbox once.")
	assert(is_equal_approx(received_hits[0].damage, 15.0), "Two combo damage must be 15.")
	var radial_hit_requests := _get_requests_for_cue(
		ability_audio_requests,
		ability.radial_hit_audio_cue
	)
	assert(radial_hit_requests.size() == 1, "One accepted radial hit must request one sound.")
	assert(
		radial_hit_requests[0].world_position == hurtbox.global_position,
		"Radial hit audio must use the struck Hurtbox position."
	)

	for _frame_index in 20:
		await physics_frame

	assert(received_hits.size() == 1, "The same activation must not hit one hurtbox twice.")

	for combo_index in ability.max_combo:
		await physics_frame
		ability.register_ball_hit(combo_hit)
		assert(
			ability.get_combo_count() == combo_index + 1,
			"Each accepted hit must increment the combo before the cap."
		)

	await physics_frame
	ability.register_ball_hit(combo_hit)
	ability.register_ball_hit(combo_hit)
	assert(ability.get_combo_count() == ability.max_combo, "The combo must remain capped.")

	print("ComboRadialAbility smoke test passed.")
	test_world.free()
	await process_frame
	quit.call_deferred()


func _create_hit_data(attack_source: Node2D) -> HitData:
	return HitData.new(
		1.0,
		Vector2.RIGHT,
		attack_source.global_position,
		0,
		0,
		attack_source.get_instance_id()
	)


func _get_requests_for_cue(
	audio_requests: Array[AudioRequest],
	cue: AudioCue
) -> Array[AudioRequest]:
	var matching_requests: Array[AudioRequest] = []

	for audio_request in audio_requests:
		if audio_request.cue == cue:
			matching_requests.append(audio_request)

	return matching_requests
