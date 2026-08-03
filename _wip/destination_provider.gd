@abstract
class_name DestinationProvider
extends Node

## 目的地を供給する部品の基底クラス。
## 所有者が activate / deactivate で有効・無効を切り替える。

signal destination_changed(destination: Vector2)


func _ready() -> void:
	set_physics_process(false)


func activate() -> void:
	set_physics_process(true)


func deactivate() -> void:
	set_physics_process(false)


## 目的地への到達通知。到達後の扱いは派生クラスが決める。
@abstract func notify_arrived() -> void
