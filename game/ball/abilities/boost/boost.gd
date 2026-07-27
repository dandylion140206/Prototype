extends Ability

@export_range(0.0, 5000.0, 10.0) var boost_speed: float = 1700.0
@export_range(0.0, 2.0, 0.01) var cooldown: float = 0.4

var _context: AbilityContext

@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _sound: AudioStreamPlayer2D = $Sound
@onready var _boost_trail: BoostTrail = $BoostTrail


func setup(context: AbilityContext) -> void:
	assert(context != null, "context must not be null.")

	_context = context
	_cooldown_timer.one_shot = true

	_boost_trail.setup(
		_context.body,
		_context.position_interpolator.get_interpolated_global_position
	)


func try_activate() -> bool:
	if _context == null:
		return false

	if not _cooldown_timer.is_stopped():
		return false

	var velocity := _context.movement.get_velocity()

	if velocity.is_zero_approx():
		return false

	var boost_velocity := velocity.normalized() * boost_speed

	_context.movement.add_velocity(boost_velocity)
	_context.hit_stop.cancel_deferred()

	if cooldown > 0.0:
		_cooldown_timer.start(cooldown)

	_boost_trail.play_boost_trail()
	activated.emit()

	return true


func teardown() -> void:
	_cooldown_timer.stop()
	_sound.stop()
	_boost_trail.stop_immediately()
	_context = null
