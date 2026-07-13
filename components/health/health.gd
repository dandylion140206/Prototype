class_name Health
extends Node

signal damaged(amount: float, current_health: float, max_health: float)
signal health_changed(current_health: float, max_health: float)
signal died

@export_range(1.0, 1000.0, 1.0) var max_health: float = 100.0

var _current_health: float = 0.0
var _is_dead: bool = false


func _ready() -> void:
	_current_health = max_health
	health_changed.emit(_current_health, max_health)


func damage(amount: float) -> void:
	if _is_dead:
		return

	if amount <= 0.0:
		return

	_current_health = maxf(_current_health - amount, 0.0)

	damaged.emit(amount, _current_health, max_health)
	health_changed.emit(_current_health, max_health)

	if _current_health <= 0.0:
		_die()


func heal(amount: float) -> void:
	if _is_dead:
		return

	if amount <= 0.0:
		return

	_current_health = minf(_current_health + amount, max_health)
	health_changed.emit(_current_health, max_health)


func get_current_health() -> float:
	return _current_health


func is_dead() -> bool:
	return _is_dead


func _die() -> void:
	if _is_dead:
		return

	_is_dead = true
	died.emit()
