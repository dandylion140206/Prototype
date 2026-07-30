class_name CoinHUD
extends Control

@onready var _coin_count_label: Label = $CoinCountLabel


func setup(initial_coin_count: int) -> void:
	set_coin_count(initial_coin_count)


func set_coin_count(coin_count: int) -> void:
	_coin_count_label.text = "coin: %d" % coin_count
