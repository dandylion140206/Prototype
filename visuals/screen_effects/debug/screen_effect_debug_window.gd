class_name ScreenEffectDebugWindow
extends PanelContainer

var _is_dragging := false
var _drag_offset := Vector2.ZERO

@onready var _drag_area: Control = %DragArea
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_drag_area.gui_input.connect(_on_drag_area_gui_input)
	_close_button.pressed.connect(hide)


func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return

	if event is InputEventMouseMotion:
		_update_drag_position()

	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and not mouse_event.pressed
		):
			_is_dragging = false
			get_viewport().set_input_as_handled()


func _on_drag_area_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	_is_dragging = mouse_event.pressed

	if _is_dragging:
		_drag_offset = get_viewport().get_mouse_position() - position

	_drag_area.accept_event()


func _update_drag_position() -> void:
	var target_position := get_viewport().get_mouse_position() - _drag_offset
	var maximum_position := get_viewport_rect().size - size

	target_position.x = clampf(
		target_position.x,
		0.0,
		maxf(maximum_position.x, 0.0),
	)
	target_position.y = clampf(
		target_position.y,
		0.0,
		maxf(maximum_position.y, 0.0),
	)

	position = target_position
