class_name Enemy
extends Node2D

signal health_changed(current_health: float, max_health: float)
signal died

@export var body_stats: EnemyBodyStats

var _is_dying: bool = false

@onready var _visual: EnemyVisual = $Visual
@onready var _hit_flash: HitFlash = %HitFlash
@onready var _hit_scale_reaction: HitScaleReaction = %HitScaleReaction
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hit_stop: HitStop = $HitStop
@onready var _health: Health = $Health
@onready var _movement: EnemyMovement = $Movement
@onready var _steering: EnemySteering = $Steering
@onready var _knockback: EnemyKnockback = $Knockback
@onready var _destination: EnemyDestination = $Destination
@onready var _hit_sound: AudioStreamPlayer2D = $HitSound
@onready var _death_sound: AudioStreamPlayer2D = $DeathSound
@onready var _crowd_agent: EnemyCrowdAgent = $CrowdAgent


func _ready() -> void:
	assert(body_stats != null, "body_stats must not be null.")

	_hit_flash.setup(_visual)
	_hit_scale_reaction.setup(_visual)
	_knockback.setup(body_stats, _hit_stop)
	_movement.setup(
		self, _hit_stop, _destination, _steering, _knockback
	)
	_crowd_agent.setup(self, body_stats, _movement, _knockback)

	_hurtbox.hit_received.connect(_on_hit_received)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)

	_on_health_changed(
		_health.get_current_health(),
		_health.max_health
	)


func set_destination(destination: Vector2) -> void:
	_destination.set_destination(destination)


func set_destination_target(target: Node2D) -> void:
	_destination.set_target(target)


func get_crowd_agent() -> EnemyCrowdAgent:
	return _crowd_agent


func get_current_health() -> float:
	return _health.get_current_health()


func get_max_health() -> float:
	return _health.max_health


func _on_hit_received(hit_data: HitData) -> void:
	if _is_dying or _health.is_dead() or hit_data.damage <= 0.0:
		return

	_knockback.apply_impact(
		hit_data.impact_velocity,
		hit_data.impact_position,
		_hurtbox.global_position
	)
	_hit_stop.start(hit_data.target_hit_stop_frames)
	_hit_flash.play()
	_hit_scale_reaction.play()
	_hit_sound.play()

	_health.damage(hit_data.damage)


func _on_health_changed(
	current_health: float,
	max_health: float
) -> void:
	_visual.update_health(current_health, max_health)
	health_changed.emit(current_health, max_health)


func _on_died() -> void:
	if _is_dying:
		return

	_is_dying = true
	_hit_stop.cancel()
	_crowd_agent.set_active(false)
	_movement.set_physics_process(false)
	_knockback.set_physics_process(false)
	_hurtbox.set_enabled(false)
	_visual.visible = false
	died.emit()

	_death_sound.play()
	await _death_sound.finished
	queue_free()
