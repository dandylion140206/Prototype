class_name Target
extends Node2D

signal health_changed(current_health: float, max_health: float)
signal died
signal exited

@onready var visual: TargetVisual = %Visual
@onready var hit_flash: HitFlash = %HitFlash
@onready var hurtbox: Hurtbox = %Hurtbox
@onready var hit_stop: HitStop = %HitStop
@onready var health: Health = %Health
@onready var movement: Movement = %Movement
@onready var target_movement: TargetMovement = %TargetMovement
@onready var hit_sound: AudioStreamPlayer2D = %HitSound
@onready var death_sound: AudioStreamPlayer2D = %DeathSound

var _is_dying := false


func _ready() -> void:
	hit_flash.setup(visual)
	movement.setup(self)
	target_movement.setup(self, movement)

	hurtbox.hit_received.connect(_on_hit_received)

	health.damaged.connect(_on_damaged)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	target_movement.exited.connect(_on_exited)

	_on_health_changed(
		health.get_current_health(),
		health.max_health
	)


func initialize_movement(
	spawn_position: Vector2,
	goal_position: Vector2,
	viewport_size: Vector2,
	spawn_margin: float
) -> void:
	target_movement.initialize(
		spawn_position,
		goal_position,
		viewport_size,
		spawn_margin,
		visual.radius
	)


func _on_hit_received(hit_data: HitData) -> void:
	health.damage(hit_data.damage)
	hit_stop.start(hit_data.target_hit_stop_duration)


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
	health_changed.emit(current_health, max_health)


func _on_died() -> void:
	if _is_dying:
		return

	_is_dying = true
	target_movement.stop()

	hurtbox.set_enabled(false)
	visual.visible = false
	died.emit()

	_play_sound_from_start(death_sound)

	await death_sound.finished

	queue_free()


func _on_exited() -> void:
	if _is_dying:
		return

	_is_dying = true
	exited.emit()
	queue_free()


func _play_sound_from_start(sound: AudioStreamPlayer2D) -> void:
	sound.stop()
	sound.play()


func get_current_health() -> float:
	return health.get_current_health()


func get_max_health() -> float:
	return health.max_health
