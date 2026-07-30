class_name WanderingTestAudioManager
extends Node

@export var hit_audio_cue: AudioCue
@export var enemy_death_audio_cue: AudioCue
@export var radial_activation_audio_cue: AudioCue
@export var radial_hit_audio_cue: AudioCue
@export var combo_hit_audio_cue: AudioCue

var _hit_audio_playback: AudioPlayback
var _enemy_death_audio_playback: AudioPlayback
var _radial_activation_audio_playback: AudioPlayback
var _radial_hit_audio_playback: AudioPlayback
var _combo_hit_audio_playback: AudioPlayback


func _ready() -> void:
	assert(hit_audio_cue != null, "hit_audio_cue must not be null.")
	assert(enemy_death_audio_cue != null, "enemy_death_audio_cue must not be null.")
	assert(radial_activation_audio_cue != null, "radial_activation_audio_cue must not be null.")
	assert(radial_hit_audio_cue != null, "radial_hit_audio_cue must not be null.")
	assert(combo_hit_audio_cue != null, "combo_hit_audio_cue must not be null.")
	_validate_audio_cue(hit_audio_cue)
	_validate_audio_cue(enemy_death_audio_cue)
	_validate_audio_cue(radial_activation_audio_cue)
	_validate_audio_cue(radial_hit_audio_cue)
	_validate_audio_cue(combo_hit_audio_cue)

	_hit_audio_playback = _create_audio_playback(&"HitAudioPlayer", hit_audio_cue)
	_enemy_death_audio_playback = _create_audio_playback(
		&"EnemyDeathAudioPlayer",
		enemy_death_audio_cue
	)
	_radial_activation_audio_playback = _create_audio_playback(
		&"RadialActivationAudioPlayer",
		radial_activation_audio_cue
	)
	_radial_hit_audio_playback = _create_audio_playback(
		&"RadialHitAudioPlayer",
		radial_hit_audio_cue
	)
	_combo_hit_audio_playback = _create_audio_playback(
		&"ComboHitAudioPlayer",
		combo_hit_audio_cue
	)


func play_ball_hit(hit_data: HitData, combo_count: int) -> void:
	assert(hit_data != null, "hit_data must not be null.")
	assert(combo_count > 0, "combo_count must be positive.")

	_hit_audio_playback.play_base_pitch(hit_data.impact_position)
	_combo_hit_audio_playback.play_combo_pitch(hit_data.impact_position, combo_count)


func play_enemy_death(world_position: Vector2) -> void:
	_enemy_death_audio_playback.play(world_position)


func play_radial_activation(world_position: Vector2) -> void:
	_radial_activation_audio_playback.play(world_position)


func play_radial_hit(hit_data: HitData) -> void:
	assert(hit_data != null, "hit_data must not be null.")

	_radial_hit_audio_playback.play(hit_data.impact_position)


func _create_audio_playback(player_name: StringName, audio_cue: AudioCue) -> AudioPlayback:
	var player := AudioStreamPlayer2D.new()
	player.name = player_name
	player.stream = audio_cue.stream
	player.bus = audio_cue.bus
	player.max_polyphony = audio_cue.max_polyphony
	player.volume_db = audio_cue.volume_db
	add_child(player)

	return AudioPlayback.new(audio_cue, player)


func _validate_audio_cue(audio_cue: AudioCue) -> void:
	assert(audio_cue.initial_pitch > 0.0, "initial_pitch must be greater than 0.0.")
	assert(
		audio_cue.pitch_random_range < audio_cue.initial_pitch,
		"pitch_random_range must be less than initial_pitch."
	)
	assert(audio_cue.pitch_increment >= 0.0, "pitch_increment must not be negative.")
	assert(audio_cue.max_pitch_increase >= 0.0, "max_pitch_increase must not be negative.")
	assert(audio_cue.combo_timeout >= 0.0, "combo_timeout must not be negative.")
	assert(audio_cue.max_polyphony >= 1, "max_polyphony must be at least 1.")


class AudioPlayback:
	var _audio_cue: AudioCue
	var _player: AudioStreamPlayer2D
	var _current_pitch_increase: float = 0.0
	var _last_playback_time: float = -INF


	func _init(audio_cue: AudioCue, player: AudioStreamPlayer2D) -> void:
		_audio_cue = audio_cue
		_player = player


	func play(world_position: Vector2) -> void:
		if _audio_cue.stream == null:
			return

		var current_time := Time.get_ticks_msec() * 0.001
		if current_time - _last_playback_time >= _audio_cue.combo_timeout:
			_current_pitch_increase = 0.0

		_player.global_position = world_position
		_player.pitch_scale = (
			_audio_cue.initial_pitch
			+ _current_pitch_increase
			+ randf_range(-_audio_cue.pitch_random_range, _audio_cue.pitch_random_range)
		)
		_player.play()

		_last_playback_time = current_time
		_current_pitch_increase = minf(
			_current_pitch_increase + _audio_cue.pitch_increment,
			_audio_cue.max_pitch_increase
		)


	func play_at_pitch(world_position: Vector2, pitch: float) -> void:
		assert(pitch > 0.0, "pitch must be greater than 0.0.")

		if _audio_cue.stream == null:
			return

		_player.global_position = world_position
		_player.pitch_scale = pitch
		_player.play()


	func play_base_pitch(world_position: Vector2) -> void:
		var pitch := (
			_audio_cue.initial_pitch
			+ randf_range(-_audio_cue.pitch_random_range, _audio_cue.pitch_random_range)
		)
		play_at_pitch(world_position, pitch)


	func play_combo_pitch(world_position: Vector2, combo_count: int) -> void:
		assert(combo_count > 0, "combo_count must be positive.")

		var pitch_increase := _audio_cue.pitch_increment * (combo_count - 1)
		var pitch := minf(
			_audio_cue.initial_pitch + pitch_increase,
			_audio_cue.initial_pitch + _audio_cue.max_pitch_increase
		)
		play_at_pitch(world_position, pitch)
