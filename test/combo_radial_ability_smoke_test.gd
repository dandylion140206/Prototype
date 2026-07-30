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
	var audio_manager := test_instance.get_node("AudioManager") as WanderingTestAudioManager
	assert(ball != null, "Ball must exist.")
	assert(scene_ability != null, "ComboRadialAbility must exist.")
	assert(combo_label != null, "ComboLabel must exist under WorldUI.")
	assert(audio_manager != null, "WanderingTestAudioManager must exist.")

	var audio_test_hit := HitData.new(
		1.0,
		Vector2.RIGHT,
		ball.global_position,
		0,
		0,
		ball.get_instance_id()
	)
	audio_manager.play_ball_hit(audio_test_hit, 1)

	var normal_hit_player := audio_manager.get_node("HitAudioPlayer") as AudioStreamPlayer2D
	var combo_hit_player := audio_manager.get_node("ComboHitAudioPlayer") as AudioStreamPlayer2D
	assert(
		normal_hit_player.pitch_scale >= 1.76 and normal_hit_player.pitch_scale <= 1.84,
		"The normal hit pitch must only use its configured random range."
	)
	assert(
		is_equal_approx(combo_hit_player.pitch_scale, 1.0),
		"The combo hit pitch must start at 1.0."
	)

	audio_manager.play_ball_hit(audio_test_hit, 5)
	assert(
		is_equal_approx(combo_hit_player.pitch_scale, 1.6),
		"The combo hit pitch must increase by 0.15 per combo."
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

	test_world.add_child(ability)
	ability.setup(attack_source)

	ability.register_ball_hit()
	ability.register_ball_hit()
	assert(ability.get_combo_count() == 1, "Multiple hits in one physics frame must add one combo.")

	await physics_frame
	ability.register_ball_hit()
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

	for _frame_index in 20:
		if not received_hits.is_empty():
			break

		await physics_frame

	assert(received_hits.size() == 1, "The expanding attack must hit the hurtbox once.")
	assert(is_equal_approx(received_hits[0].damage, 15.0), "Two combo damage must be 15.")

	for _frame_index in 20:
		await physics_frame

	assert(received_hits.size() == 1, "The same activation must not hit one hurtbox twice.")

	for combo_index in ability.max_combo:
		await physics_frame
		ability.register_ball_hit()
		assert(
			ability.get_combo_count() == combo_index + 1,
			"Each accepted hit must increment the combo before the cap."
		)

	await physics_frame
	ability.register_ball_hit()
	ability.register_ball_hit()
	assert(ability.get_combo_count() == ability.max_combo, "The combo must remain capped.")

	print("ComboRadialAbility smoke test passed.")
	test_world.free()
	await process_frame
	quit.call_deferred()
