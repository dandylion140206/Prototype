class_name Ball
extends Node2D

signal hit_landed(hit_data: HitData)

@export_range(0.9, 1.0, 0.001) var hit_speed_multiplier: float = 0.985

var _target_position: Vector2 = Vector2.ZERO

@onready var _movement: BallMovement = $Movement
@onready var _hit_controller: BallHitController = $HitController
@onready var _hit_stop: HitStop = $HitStop
@onready var _ability_controller: AbilityController = $AbilityController
@onready var _physics_position_interpolator: PhysicsPositionInterpolator = $PhysicsPositionInterpolator


func _ready() -> void:
	_movement.setup(self)
	_hit_controller.setup(self)
	_physics_position_interpolator.setup(self)

	var ability_context := AbilityContext.new(
		self,
		_movement,
		_hit_stop,
		_physics_position_interpolator
	)

	_ability_controller.setup(ability_context)
	_target_position = global_position


func _physics_process(delta: float) -> void:
	if _hit_stop.is_active():
		_physics_position_interpolator.record_position()
		return

	_movement.update_velocity(global_position, _target_position, delta)

	var planned_motion := _movement.get_planned_motion(delta)
	var landed_hits: Array[HitData] = _hit_controller.apply_hits(
		planned_motion,
		_movement.get_velocity()
	)

	_movement.move(planned_motion)
	_hit_controller.update_contacting_hurtboxes()

	if not landed_hits.is_empty():
		_handle_landed_hits(landed_hits)

	_physics_position_interpolator.record_position()


func set_target_position(target_position: Vector2) -> void:
	_target_position = target_position


func get_velocity() -> Vector2:
	return _movement.get_velocity()


func get_interpolated_global_position() -> Vector2:
	return _physics_position_interpolator.get_interpolated_global_position()


func request_ability_activation() -> bool:
	return _ability_controller.try_activate()


func _handle_landed_hits(landed_hits: Array[HitData]) -> void:
	_movement.scale_velocity(hit_speed_multiplier)
	_start_attacker_hit_stop(landed_hits)

	for hit_data in landed_hits:
		hit_landed.emit(hit_data)


func _start_attacker_hit_stop(hit_data_list: Array[HitData]) -> void:
	var hit_stop_frames := 0

	for hit_data in hit_data_list:
		hit_stop_frames = maxi(
			hit_stop_frames,
			hit_data.attacker_hit_stop_frames
		)

	_hit_stop.start(hit_stop_frames)
