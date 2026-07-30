class_name CoinInventory
extends Node

signal coin_count_changed(coin_count: int)

@export_range(0, 1000000, 1, "or_greater") var initial_coin_count: int = 0

var _coin_count: int


func _ready() -> void:
	_coin_count = initial_coin_count


func add_coin(amount: int = 1) -> void:
	assert(amount > 0, "amount must be greater than zero.")

	_coin_count += amount
	coin_count_changed.emit(_coin_count)


func try_take_coin() -> bool:
	if _coin_count <= 0:
		return false

	_coin_count -= 1
	coin_count_changed.emit(_coin_count)
	return true


func get_coin_count() -> int:
	return _coin_count
