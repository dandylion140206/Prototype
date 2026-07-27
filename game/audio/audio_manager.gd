class_name AudioManager
extends Node

@export var hit_audio_cue: AudioCue
@export var enemy_death_audio_cue: AudioCue

var _current_pitch: float = 1.0
var _last_playback_time: float = -INF

var _hit_audio_player: AudioStreamPlayer2D
var _enemy_death_audio_player: AudioStreamPlayer2D


func _ready() -> void:
	assert(hit_audio_cue != null, "hit_audio_cue must not be null.")
	assert(enemy_death_audio_cue != null, "enemy_death_audio_cue must not be null.")
	_validate_audio_cue(hit_audio_cue)
	_validate_audio_cue(enemy_death_audio_cue)

	_current_pitch = hit_audio_cue.initial_pitch
	_hit_audio_player = _create_audio_player(&"HitAudioPlayer", hit_audio_cue)
	_enemy_death_audio_player = _create_audio_player(&"EnemyDeathAudioPlayer", enemy_death_audio_cue)


func play_hit(hit_data: HitData) -> void:
	assert(hit_data != null, "hit_data must not be null.")

	if hit_audio_cue.stream == null:
		return

	var current_time := Time.get_ticks_msec() * 0.001
	if current_time - _last_playback_time >= hit_audio_cue.combo_timeout:
		_current_pitch = hit_audio_cue.initial_pitch

	_hit_audio_player.global_position = hit_data.impact_position
	_hit_audio_player.pitch_scale = minf(
		_current_pitch + _get_random_pitch_offset(hit_audio_cue),
		hit_audio_cue.max_pitch
	)
	_hit_audio_player.play()

	_last_playback_time = current_time
	_current_pitch = minf(_current_pitch + hit_audio_cue.pitch_increment, hit_audio_cue.max_pitch)


func play_enemy_death(world_position: Vector2) -> void:
	if enemy_death_audio_cue.stream == null:
		return

	_enemy_death_audio_player.global_position = world_position
	_enemy_death_audio_player.pitch_scale = 1.0 + _get_random_pitch_offset(enemy_death_audio_cue)
	_enemy_death_audio_player.play()


func _setup_audio_player(player: AudioStreamPlayer2D, audio_cue: AudioCue) -> void:
	player.stream = audio_cue.stream
	player.bus = audio_cue.bus
	player.max_polyphony = audio_cue.max_polyphony
	player.volume_db = audio_cue.volume_db


func _create_audio_player(player_name: StringName, audio_cue: AudioCue) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = player_name
	_setup_audio_player(player, audio_cue)
	add_child(player)

	return player


func _validate_audio_cue(audio_cue: AudioCue) -> void:
	assert(audio_cue.initial_pitch > 0.0, "initial_pitch must be greater than 0.0.")
	assert(
		audio_cue.pitch_random_range < audio_cue.initial_pitch,
		"pitch_random_range must be less than initial_pitch."
	)
	assert(audio_cue.pitch_increment >= 0.0, "pitch_increment must not be negative.")
	assert(audio_cue.max_pitch >= audio_cue.initial_pitch, "max_pitch must be at least initial_pitch.")
	assert(audio_cue.combo_timeout >= 0.0, "combo_timeout must not be negative.")
	assert(audio_cue.max_polyphony >= 1, "max_polyphony must be at least 1.")


func _get_random_pitch_offset(audio_cue: AudioCue) -> float:
	return randf_range(-audio_cue.pitch_random_range, audio_cue.pitch_random_range)
