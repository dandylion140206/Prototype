extends Node2D

@export_range(0.0, 5000.0, 10.0) var impact_speed: float = 1000.0
@export_range(0.1, 30.0, 0.1) var mass: float = 1.0

var _stats: EnemyBodyStats

@onready var _knockback: EnemyKnockback = $Knockback


func _ready() -> void:
	_stats = EnemyBodyStats.new()
	_stats.mass = mass

	_knockback.setup(_stats, null)


func _physics_process(delta: float) -> void:
	global_position += _knockback.get_velocity() * delta


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("primary_action"):
		return

	var impact_position := get_global_mouse_position()
	var direction := (global_position - impact_position).normalized()
	if direction.is_zero_approx():
		return

	var impact_velocity := direction * impact_speed

	_knockback.apply_impact(
		impact_velocity,
		impact_position,
		global_position
	)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color.WHITE)
