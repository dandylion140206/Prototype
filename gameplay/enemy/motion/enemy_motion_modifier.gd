class_name EnemyMotionModifier
extends Resource

@export_range(0.0, 10.0, 0.01, "or_greater") var speed_multiplier: float = 1.0
@export_range(0.001, 10.0, 0.001, "or_greater") var mass_multiplier: float = 1.0


func validate() -> void:
	assert(speed_multiplier >= 0.0, "speed_multiplier must not be negative.")
	assert(mass_multiplier > 0.0, "mass_multiplier must be greater than zero.")
