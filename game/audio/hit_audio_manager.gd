class_name HitAudioManager
extends Node

@export var hit_stream: AudioStream
@export_range(0.01, 3.0, 0.01) var initial_pitch: float = 1.0
@export_range(0.0, 1.0, 0.01) var pitch_increment: float = 0.03
@export_range(0.01, 3.0, 0.01) var max_pitch: float = 1.3
@export_range(0.0, 5.0, 0.01) var combo_timeout: float = 0.3
@export_range(1, 32, 1) var max_polyphony: int = 4
@export_range(-80.0, 24.0, 0.1) var volume_db: float = 0.0

var _ball: Ball
var _current_pitch: float = 1.0
var _last_playback_time: float = -INF

@onready var _player: AudioStreamPlayer2D = $HitAudioPlayer


func _ready() -> void:
	assert(initial_pitch > 0.0, "initial_pitch must be greater than 0.0.")
	assert(pitch_increment >= 0.0, "pitch_increment must not be negative.")
	assert(max_pitch >= initial_pitch, "max_pitch must be at least initial_pitch.")
	assert(combo_timeout >= 0.0, "combo_timeout must not be negative.")
	assert(max_polyphony >= 1, "max_polyphony must be at least 1.")

	_current_pitch = initial_pitch
	_player.stream = hit_stream
	_player.max_polyphony = max_polyphony


func setup(ball: Ball) -> void:
	assert(ball != null, "ball must not be null.")
	_ball = ball


func play_hit(_hit_data: HitData) -> void:
	assert(_ball != null, "HitAudioManager must be setup before play_hit().")

	if _player.stream == null:
		return

	var current_time := Time.get_ticks_msec() * 0.001
	if current_time - _last_playback_time >= combo_timeout:
		_current_pitch = initial_pitch

	_player.global_position = _ball.global_position
	_player.pitch_scale = _current_pitch
	_player.volume_db = volume_db
	_player.play()

	_last_playback_time = current_time
	_current_pitch = minf(_current_pitch + pitch_increment, max_pitch)
