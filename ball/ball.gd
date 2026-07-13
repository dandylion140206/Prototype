class_name Ball
extends Node2D

signal active_ability_activated

var _target_position := Vector2.ZERO

@onready var hitbox: Hitbox = %Hitbox
@onready var movement: Movement = %Movement
@onready var impact_attack: ImpactAttack = %ImpactAttack
@onready var hit_stop: HitStop = %HitStop
@onready var ability_controller: AbilityController = %AbilityController
@onready var physics_position_interpolator: PhysicsPositionInterpolator = %PhysicsPositionInterpolator


func _ready() -> void:
	movement.setup(self)
	impact_attack.setup(movement.get_speed)
	physics_position_interpolator.setup(self)

	var ability_context := AbilityContext.new(
		self,
		movement,
		hit_stop.cancel_deferred,
		get_interpolated_global_position
	)

	ability_controller.setup(ability_context)

	hitbox.hit_detected.connect(impact_attack.apply_hit)
	impact_attack.hit_landed.connect(_on_hit_landed)
	ability_controller.active_ability_activated.connect(active_ability_activated.emit)

	_target_position = global_position


func _physics_process(delta: float) -> void:
	if hit_stop.is_active():
		physics_position_interpolator.record_position()
		return

	movement.update_velocity(
		global_position,
		_target_position,
		delta
	)
	movement.move(delta)
	physics_position_interpolator.record_position()


func set_target_position(target_position: Vector2) -> void:
	_target_position = target_position


func request_active_ability() -> bool:
	return ability_controller.try_activate()


func get_interpolated_global_position() -> Vector2:
	return physics_position_interpolator.get_interpolated_global_position()


func _on_hit_landed(hit_data: HitData) -> void:
	hit_stop.start(hit_data.attacker_hit_stop_duration)
