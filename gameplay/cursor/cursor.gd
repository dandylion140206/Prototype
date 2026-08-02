extends Node2D


func _ready() -> void:
	set_os_cursor_visible(false)


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func set_os_cursor_visible(os_cursor_visible: bool) -> void:
	visible = not os_cursor_visible
	set_process(not os_cursor_visible)

	if os_cursor_visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
