class_name DebugOverlayLayer
extends CanvasLayer

const MILLISECONDS_PER_SECOND := 1000.0

@export_range(0.05, 3.0, 0.05) var update_interval: float = 0.10
@export var toggle_keycode: Key = KEY_BACKSPACE

var _last_update_time_msec: int = 0

@onready var _panel_container: VBoxContainer = $PanelContainer


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	visible = true
	_update_panels()


func _process(_delta: float) -> void:
	var current_time_msec := Time.get_ticks_msec()

	if current_time_msec - _last_update_time_msec < update_interval * MILLISECONDS_PER_SECOND:
		return

	_last_update_time_msec = current_time_msec
	_update_panels()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey

	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode != toggle_keycode:
		return

	visible = not visible
	get_viewport().set_input_as_handled()


func _update_panels() -> void:
	for child in _panel_container.get_children():
		var panel := child as DebugOverlayPanel

		if panel != null:
			panel.update_display()
