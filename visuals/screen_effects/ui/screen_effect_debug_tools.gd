class_name ScreenEffectDebugTools
extends Node

@export var screen_effects: ScreenEffects

@onready var _debug_ui: ScreenEffectDebugUI = $ScreenEffectDebugUI


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	assert(screen_effects != null, "ScreenEffects must not be null")
	assert(_debug_ui != null, "ScreenEffectDebugUI must not be null")

	_debug_ui.setup(screen_effects.get_models())
