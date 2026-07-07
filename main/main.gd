extends Node

@onready var ball: Ball = $Ball
@onready var effects_layer: EffectsLayer = $EffectsLayer


func _ready() -> void:
	effects_layer.setup(ball)

	ball.speed_updated.connect(effects_layer.update_ball_speed)
	ball.boosted.connect(effects_layer.on_ball_boosted)
