class_name Target
extends Node2D

@export var hit_stop_profile: HitStopProfile

@onready var visual: TargetVisual = %Visual
@onready var hit_flash: HitFlash = %HitFlash
@onready var hurtbox: Hurtbox = %Hurtbox
@onready var health: Health = %Health
@onready var health_bar: HealthBar = %HealthBar
@onready var hit_sound: AudioStreamPlayer2D = %HitSound
@onready var death_sound: AudioStreamPlayer2D = %DeathSound
@onready var hit_stop: HitStop = %HitStop

var _is_dying: bool = false


func _ready() -> void:
	assert(hit_stop_profile != null, "hit_stop_profile must not be null.")

	hit_flash.setup(visual)
	hurtbox.setup(health)

	hurtbox.hit_received.connect(_on_hit_received)

	health.damaged.connect(_on_damaged)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)

	_on_health_changed(
		health.get_current_health(),
		health.max_health
	)


func _on_damaged(
	_amount: float,
	_current_health: float,
	_max_health: float
) -> void:
	if _is_dying:
		return

	hit_flash.flash()
	_play_sound_from_start(hit_sound)


func _on_health_changed(current_health: float, max_health: float) -> void:
	visual.update_health(current_health, max_health)
	health_bar.update_health(current_health, max_health)


func _on_died() -> void:
	if _is_dying:
		return

	_is_dying = true

	hurtbox.set_enabled(false)
	visual.visible = false
	health_bar.hide_immediately()

	_play_sound_from_start(death_sound)

	await death_sound.finished

	queue_free()


func _on_hit_received(hit_speed: float) -> void:
	var hit_stop_duration := hit_stop_profile.calculate_duration(hit_speed)
	hit_stop.start(hit_stop_duration)


func _play_sound_from_start(sound: AudioStreamPlayer2D) -> void:
	sound.stop()
	sound.play()
