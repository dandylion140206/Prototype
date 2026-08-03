class_name Enemy
extends Node2D

const ENEMY_MOTION_MODIFIER_RESOURCE = preload("res://gameplay/enemy/motion/enemy_motion_modifier.gd")

signal health_changed(current_health: float, max_health: float)
signal died

@export var stats: EnemyStats

var _is_dying: bool = false
var _movement_behavior: EnemyMovementBehavior

@onready var _visual: Node2D = $Visual
@onready var _hit_flash: HitFlash = %HitFlash
@onready var _spawn_animation: EnemySpawnAnimation = %SpawnAnimation
@onready var _hit_scale_reaction: HitScaleReaction = %HitScaleReaction
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hit_stop: HitStop = $HitStop
@onready var _health: Health = $Health
@onready var _motor: EnemyMotor = $Motor
@onready var _knockback: EnemyKnockback = $Knockback
@onready var _crowd_agent: EnemyCrowdAgent = $CrowdAgent
@onready var _motion_modifiers: EnemyMotionModifierStack = $MotionModifiers


func _ready() -> void:
	assert(stats != null, "stats must not be null.")
	stats.validate()

	_hit_flash.setup(_visual)
	_hit_scale_reaction.setup(_visual, _visual.set_hit_scale)
	_hit_scale_reaction.reaction_started.connect(_visual.start_hit_scale)
	_hit_scale_reaction.reaction_finished.connect(_visual.finish_hit_scale)
	_hurtbox.set_enabled(false)
	_spawn_animation.setup(_visual.set_spawn_scale)
	_spawn_animation.hit_detection_ready.connect(_on_spawn_animation_hit_detection_ready)
	_spawn_animation.play()
	_motion_modifiers.setup(stats.mass)
	_knockback.setup(_motion_modifiers)

	var idle_behavior := EnemyIdleBehavior.new()
	add_child(idle_behavior)
	idle_behavior.name = "MovementBehavior"
	_movement_behavior = idle_behavior
	_motor.setup(
		self,
		stats,
		_movement_behavior,
		_knockback,
		_motion_modifiers,
		_hit_stop
	)
	_crowd_agent.setup(_motor, _motion_modifiers, _hit_stop)

	_hurtbox.hit_received.connect(_on_hit_received)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)

	_on_health_changed(_health.get_current_health(), _health.max_health)


func get_crowd_agent() -> EnemyCrowdAgent:
	return _crowd_agent


func get_motor() -> EnemyMotor:
	return _motor


func set_movement_behavior(behavior: EnemyMovementBehavior) -> void:
	assert(behavior != null, "behavior must not be null.")
	assert(behavior.get_parent() == null, "behavior must not have a parent.")

	var previous_behavior := _movement_behavior
	if previous_behavior != null:
		if previous_behavior.get_parent() == self:
			remove_child(previous_behavior)
		previous_behavior.queue_free()

	add_child(behavior)
	behavior.name = "MovementBehavior"
	_movement_behavior = behavior
	_motor.set_movement_behavior(behavior)
	behavior.activate()


func start_wandering(
	area: Rect2,
	arrival_distance: float,
	p_min_destination_duration: float,
	p_max_destination_duration: float
) -> void:
	var behavior := EnemyWanderBehavior.new()
	behavior.configure(
		area,
		arrival_distance,
		p_min_destination_duration,
		p_max_destination_duration
	)
	set_movement_behavior(behavior)


func move_to(position: Vector2, arrival_distance: float) -> void:
	var behavior := EnemyMoveToPositionBehavior.new()
	behavior.configure(position, arrival_distance)
	set_movement_behavior(behavior)


func follow(target: Node2D, arrival_distance: float) -> void:
	assert(target != null, "target must not be null.")
	var behavior := EnemyFollowTargetBehavior.new()
	behavior.configure(target, arrival_distance)
	set_movement_behavior(behavior)


func stop_moving() -> void:
	set_movement_behavior(EnemyIdleBehavior.new())


func apply_knockback(impact_velocity: Vector2, impact_position: Vector2) -> void:
	if _is_dying or _health.is_dead():
		return

	_knockback.apply_knockback(impact_velocity, impact_position, global_position)


func add_motion_modifier(modifier: ENEMY_MOTION_MODIFIER_RESOURCE) -> int:
	return _motion_modifiers.add_modifier(modifier)


func remove_motion_modifier(modifier_id: int) -> void:
	_motion_modifiers.remove_modifier(modifier_id)


func get_velocity() -> Vector2:
	return _motor.get_effective_velocity()


func get_current_health() -> float:
	return _health.get_current_health()


func get_max_health() -> float:
	return _health.max_health


func _on_hit_received(hit_data: HitData) -> void:
	if _is_dying or _health.is_dead():
		return

	if not hit_data.impact_velocity.is_zero_approx():
		apply_knockback(hit_data.impact_velocity, hit_data.impact_position)

	if hit_data.damage <= 0.0:
		return

	_hit_stop.start(hit_data.target_hit_stop_frames)
	_hit_flash.play()
	_hit_scale_reaction.play()
	_health.damage(hit_data.damage)


func _on_health_changed(current_health: float, max_health: float) -> void:
	_visual.update_health(current_health, max_health)
	health_changed.emit(current_health, max_health)


func _on_spawn_animation_hit_detection_ready() -> void:
	if _is_dying:
		return

	_hurtbox.set_enabled(true)


func _on_died() -> void:
	if _is_dying:
		return

	_is_dying = true
	_hit_stop.cancel()
	_hurtbox.set_enabled(false)
	_visual.visible = false
	died.emit()
	queue_free()
