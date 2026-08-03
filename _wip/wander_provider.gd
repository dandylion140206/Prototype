class_name WanderProvider
extends DestinationProvider

## エリア内のランダムな点を目的地として供給する。

@export_range(0.0, 5.0, 0.1) var min_wait_time: float = 0.5
@export_range(0.0, 5.0, 0.1) var max_wait_time: float = 2.0

var area: Rect2 = Rect2()

var _wait_time_left: float = 0.0


func _ready() -> void:
	super()

	assert(min_wait_time <= max_wait_time, "min_wait_time は max_wait_time 以下にしてください。")


func _physics_process(delta: float) -> void:
	if _wait_time_left <= 0.0:
		return

	_wait_time_left -= delta
	if _wait_time_left <= 0.0:
		_select_destination()


func activate() -> void:
	super()

	_wait_time_left = 0.0
	_select_destination()


func notify_arrived() -> void:
	_wait_time_left = randf_range(min_wait_time, max_wait_time)


func _select_destination() -> void:
	assert(area.has_area(), "放浪エリアが設定されていません。")

	var x := randf_range(area.position.x, area.end.x)
	var y := randf_range(area.position.y, area.end.y)
	destination_changed.emit(Vector2(x, y))
