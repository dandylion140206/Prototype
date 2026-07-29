class_name CoinSystem
extends Node2D

signal coin_count_changed(coin_count: int)
signal coin_collected(world_position: Vector2)

@export var coin_scene: PackedScene

var _coin_count: int = 0

@onready var _coin_box: CoinBox = $CoinBox
@onready var _coins: Node2D = $Coins
@onready var _coin_label: Label = $CoinUI/CoinLabel


func _ready() -> void:
	assert(coin_scene != null, "coin_scene must not be null.")
	assert(_coin_box != null, "CoinBox must exist.")
	assert(_coins != null, "Coins must exist.")
	assert(_coin_label != null, "CoinLabel must exist.")
	_update_coin_label()


func drop_coin(drop_global_position: Vector2) -> void:
	var coin := coin_scene.instantiate() as Coin
	if coin == null:
		push_error("coin_scene root must be Coin.")
		return

	_coins.add_child(coin)
	coin.global_position = drop_global_position
	coin.collected.connect(_on_coin_collected)
	coin.collect_to(_coin_box.global_position)


func get_coin_count() -> int:
	return _coin_count


func get_coin_box_global_position() -> Vector2:
	return _coin_box.global_position


func is_global_position_inside(global_position: Vector2) -> bool:
	return _coin_box.is_global_position_inside(global_position)


func try_take_coin() -> bool:
	if _coin_count <= 0:
		return false

	_coin_count -= 1
	_notify_coin_count_changed()
	return true


func _on_coin_collected() -> void:
	_coin_count += 1
	_notify_coin_count_changed()
	coin_collected.emit(_coin_box.global_position)
	_coin_box.play_collect_animation()


func _notify_coin_count_changed() -> void:
	_update_coin_label()
	coin_count_changed.emit(_coin_count)


func _update_coin_label() -> void:
	_coin_label.text = "coin: %d" % _coin_count
