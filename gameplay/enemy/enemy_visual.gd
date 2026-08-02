class_name EnemyVisual
extends Node2D

signal scale_changed(scale_value: Vector2)

@export_range(1.0, 500.0, 1.0) var radius: float = 40.0
@export var full_health_color: Color = Color(0.2, 0.7, 1.0, 1.0)
@export var low_health_color: Color = Color(1.0, 0.3, 0.3, 1.0)

var _health_ratio: float = 1.0
var _base_scale: Vector2 = Vector2.ONE
var _spawn_scale: Vector2 = Vector2.ONE
var _hit_scale: float = 1.0
var _is_hit_scale_active: bool = false


func _ready() -> void:
	_base_scale = scale
	_apply_scale()


func _draw() -> void:
	var damage_ratio := 1.0 - _health_ratio
	var color := full_health_color.lerp(low_health_color, damage_ratio)
	draw_circle(Vector2.ZERO, radius, color)


func update_health(current_health: float, max_health: float) -> void:
	if max_health <= 0.0:
		_health_ratio = 0.0
	else:
		_health_ratio = clampf(current_health / max_health, 0.0, 1.0)

	queue_redraw()


func set_spawn_scale(scale_value: Vector2) -> void:
	_spawn_scale = scale_value
	_apply_scale()


func start_hit_scale() -> void:
	_is_hit_scale_active = true
	_apply_scale()


func set_hit_scale(scale_value: float) -> void:
	_hit_scale = scale_value
	_apply_scale()


func finish_hit_scale() -> void:
	_is_hit_scale_active = false
	_hit_scale = 1.0
	_apply_scale()


func _apply_scale() -> void:
	var applied_scale: Vector2

	if _is_hit_scale_active:
		applied_scale = _base_scale * _hit_scale
	else:
		applied_scale = _base_scale * _spawn_scale

	scale = applied_scale
	scale_changed.emit(applied_scale)
