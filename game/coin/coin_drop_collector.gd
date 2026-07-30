class_name CoinDropCollector
extends Node

signal coin_collected(world_position: Vector2)

@export var dropped_coin_scene: PackedScene

var _coin_stash: CoinStash
var _coin_inventory: CoinInventory
var _active_coins: Node


func setup(
	coin_stash: CoinStash,
	coin_inventory: CoinInventory,
	active_coins: Node
) -> void:
	assert(coin_stash != null, "coin_stash must not be null.")
	assert(coin_inventory != null, "coin_inventory must not be null.")
	assert(active_coins != null, "active_coins must not be null.")
	assert(dropped_coin_scene != null, "dropped_coin_scene must not be null.")

	_coin_stash = coin_stash
	_coin_inventory = coin_inventory
	_active_coins = active_coins


func drop_coin(drop_global_position: Vector2) -> void:
	assert(_coin_stash != null, "setup must be called before dropping coins.")

	var dropped_coin := dropped_coin_scene.instantiate() as DroppedCoin
	if dropped_coin == null:
		push_error("dropped_coin_scene root must inherit DroppedCoin.")
		return

	_active_coins.add_child(dropped_coin)
	dropped_coin.global_position = drop_global_position
	dropped_coin.collected.connect(_on_dropped_coin_collected, CONNECT_ONE_SHOT)
	dropped_coin.collect_to(_coin_stash.get_collect_global_position())


func get_active_coin_count() -> int:
	if _active_coins == null:
		return 0

	return _active_coins.get_child_count()


func _on_dropped_coin_collected() -> void:
	var collect_position := _coin_stash.get_collect_global_position()
	_coin_inventory.add_coin()
	_coin_stash.play_collect_animation()
	coin_collected.emit(collect_position)
