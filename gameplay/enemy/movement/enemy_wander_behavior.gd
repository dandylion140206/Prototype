class_name EnemyWanderBehavior
extends EnemyMovementBehavior

@export var wander_area: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
@export_range(0.0, 1000.0, 1.0, "or_greater") var arrival_distance: float = 0.0
@export_range(0.001, 60.0, 0.01, "or_greater") var min_destination_duration: float = 1.0
@export_range(0.001, 60.0, 0.01, "or_greater") var max_destination_duration: float = 1.0

var _random := RandomNumberGenerator.new()
var _destination := Vector2.ZERO
var _destination_time_left: float = 0.0
var _is_initialized: bool = false


func _ready() -> void:
	if not _is_initialized:
		activate()


func activate() -> void:
	if _is_initialized:
		return

	_validate()
	_random.randomize()
	_select_destination()
	_is_initialized = true


func configure(
	p_wander_area: Rect2,
	p_arrival_distance: float,
	p_min_destination_duration: float,
	p_max_destination_duration: float
) -> void:
	wander_area = p_wander_area
	arrival_distance = p_arrival_distance
	min_destination_duration = p_min_destination_duration
	max_destination_duration = p_max_destination_duration
	_validate()


func get_desired_velocity(
	current_position: Vector2,
	effective_target_speed: float,
	delta: float
) -> Vector2:
	if not _is_initialized:
		activate()

	var arrival_distance_squared := arrival_distance * arrival_distance
	if current_position.distance_squared_to(_destination) <= arrival_distance_squared:
		_select_destination()
	else:
		_destination_time_left -= maxf(delta, 0.0)
		if _destination_time_left <= 0.0:
			_select_destination()

	var direction := (_destination - current_position).normalized()
	return direction * effective_target_speed


func _select_destination() -> void:
	_destination = Vector2(
		_random.randf_range(wander_area.position.x, wander_area.end.x),
		_random.randf_range(wander_area.position.y, wander_area.end.y)
	)
	_destination_time_left = _random.randf_range(
		min_destination_duration,
		max_destination_duration
	)


func _validate() -> void:
	assert(wander_area.size.x > 0.0, "wander_area width must be greater than zero.")
	assert(wander_area.size.y > 0.0, "wander_area height must be greater than zero.")
	assert(arrival_distance >= 0.0, "arrival_distance must not be negative.")
	assert(
		min_destination_duration > 0.0,
		"min_destination_duration must be greater than zero."
	)
	assert(
		max_destination_duration > 0.0,
		"max_destination_duration must be greater than zero."
	)
	assert(
		min_destination_duration <= max_destination_duration,
		"min_destination_duration must not exceed max_destination_duration."
	)
