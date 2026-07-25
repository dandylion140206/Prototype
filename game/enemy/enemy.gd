class_name Enemy
extends CharacterBody2D

signal health_changed(current_health: float, max_health: float)
signal died

var _is_dying: bool = false

@onready var _visual: EnemyVisual = %Visual
@onready var _hit_flash: HitFlash = %HitFlash
@onready var _hit_scale_reaction: HitScaleReaction = %HitScaleReaction
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hit_stop: HitStop = %HitStop
@onready var _health: Health = %Health
@onready var _enemy_destination: EnemyDestination = %Destination
@onready var _enemy_steering: EnemySteering = %Steering
@onready var _enemy_movement: EnemyMovement = %Movement
@onready var _hit_sound: AudioStreamPlayer2D = %HitSound
@onready var _death_sound: AudioStreamPlayer2D = %DeathSound


func _ready() -> void:
	_hit_flash.setup(_visual)
	_hit_scale_reaction.setup(_visual)
	_enemy_movement.setup(self, _hit_stop, _enemy_destination, _enemy_steering)

	_hurtbox.hit_received.connect(_on_hit_received)
	_health.damaged.connect(_on_damaged)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)

	_on_health_changed(_health.get_current_health(), _health.max_health)


func set_destination(destination: Vector2) -> void:
	_enemy_destination.set_destination(destination)
	_enemy_movement.start()


func set_destination_target(destination_target: Node2D) -> void:
	_enemy_destination.set_destination_target(destination_target)
	_enemy_movement.start()


func clear_destination_target() -> void:
	_enemy_destination.clear_destination_target()
	if not _enemy_destination.has_destination():
		_enemy_movement.stop()


func clear_destination() -> void:
	_enemy_destination.clear_destination()
	_enemy_movement.stop()


func stop_movement() -> void:
	_enemy_movement.stop()


func get_current_health() -> float:
	return _health.get_current_health()


func get_max_health() -> float:
	return _health.max_health


func set_crowd_acceleration(crowd_acceleration: Vector2) -> void:
	_enemy_movement.set_crowd_acceleration(crowd_acceleration)


func get_normal_velocity() -> Vector2:
	return _enemy_movement.get_normal_velocity()


func get_external_knockback_velocity() -> Vector2:
	return _enemy_movement.get_external_knockback_velocity()


func get_enemy_movement() -> EnemyMovement:
	return _enemy_movement


func _on_hit_received(hit_data: HitData) -> void:
	if _is_dying or _health.is_dead() or hit_data.damage <= 0.0:
		return

	_health.damage(hit_data.damage)
	if _is_dying:
		return

	_enemy_movement.add_knockback(hit_data.knockback_velocity)
	_hit_stop.start(hit_data.target_hit_stop_duration)


func _on_damaged(
	_amount: float,
	_current_health: float,
	_max_health: float
) -> void:
	if _is_dying:
		return

	_hit_flash.play()
	_hit_scale_reaction.play()
	_play_sound_from_start(_hit_sound)


func _on_health_changed(current_health: float, max_health: float) -> void:
	_visual.update_health(current_health, max_health)
	health_changed.emit(current_health, max_health)


func _on_died() -> void:
	if _is_dying:
		return

	_is_dying = true
	remove_from_group("enemy")
	_enemy_movement.stop()
	_hurtbox.set_enabled(false)
	_visual.visible = false
	died.emit()

	_play_sound_from_start(_death_sound)
	await _death_sound.finished
	queue_free()


func _play_sound_from_start(sound: AudioStreamPlayer2D) -> void:
	sound.stop()
	sound.play()
