class_name ChaseProvider
extends DestinationProvider

## 追従対象の座標を目的地として供給する。

signal target_lost

var target: Node2D = null


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		deactivate()
		target_lost.emit()
		return

	destination_changed.emit(target.global_position)


## 追従では到達しても目的地を変えないため、何もしない。
func notify_arrived() -> void:
	pass
