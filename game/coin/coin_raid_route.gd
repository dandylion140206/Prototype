class_name CoinRaidRoute
extends Node2D

signal enemy_spawned(enemy: Enemy)
signal enemy_died(enemy: Enemy, world_position: Vector2)
signal coin_collected(world_position: Vector2)
signal coin_count_changed(coin_count: int)
signal enemy_escaped(enemy: Enemy)

@onready var _enemy_spawner: WaveEnemySpawner = $EnemySystem/EnemySpawner
@onready var _enemy_crowd_system: EnemyCrowdSystem = $EnemySystem/EnemyCrowdSystem
@onready var _active_enemies: Node2D = $EnemySystem/ActiveEnemies
@onready var _enemy_spawn_line: LineSegment2D = $EnemySpawnLine
@onready var _coin_stash: CoinStash = $CoinStash
@onready var _approach_area: CoinApproachTargetProvider = $CoinStash/ApproachArea
@onready var _raid_area: CoinRaidArea = $CoinStash/RaidArea
@onready var _enemy_escape_line: LineSegment2D = $EnemyEscapeLine
@onready var _coin_inventory: CoinInventory = $CoinInventory
@onready var _coin_drop_collector: CoinDropCollector = $CoinDropCollector
@onready var _active_coins: Node2D = $CoinDropCollector/ActiveCoins
@onready var _coin_raid_controller: CoinRaidController = $CoinRaidController


func _ready() -> void:
	_approach_area.setup(_raid_area, _active_enemies)
	_coin_raid_controller.setup(
		_coin_inventory,
		_approach_area,
		_raid_area,
		_enemy_escape_line
	)
	_coin_drop_collector.setup(_coin_stash, _coin_inventory, _active_coins)

	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_coin_inventory.coin_count_changed.connect(_on_coin_count_changed)
	_coin_drop_collector.coin_collected.connect(_on_coin_collected)
	_coin_raid_controller.enemy_escaped.connect(_on_enemy_escaped)

	_start_spawner.call_deferred()


func get_enemy_count() -> int:
	return _active_enemies.get_child_count()


func get_coin_count() -> int:
	return _coin_inventory.get_coin_count()


func get_crowd_agent_count() -> int:
	return _enemy_crowd_system.get_agent_count()


func get_crowd_pair_count() -> int:
	return _enemy_crowd_system.get_crowd_pair_count()


func get_approaching_enemy_count() -> int:
	return _coin_raid_controller.get_approaching_enemy_count()


func get_carrying_enemy_count() -> int:
	return _coin_raid_controller.get_carrying_enemy_count()


func get_approach_target_count() -> int:
	return _approach_area.get_assignment_count()


func get_active_coin_count() -> int:
	return _coin_drop_collector.get_active_coin_count()


func _start_spawner() -> void:
	_enemy_spawner.setup(_enemy_spawn_line, _active_enemies)


func _on_enemy_spawned(enemy: Enemy) -> void:
	_enemy_crowd_system.register(enemy.get_crowd_agent())
	_coin_raid_controller.register_enemy(enemy)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy_spawned.emit(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	var death_position := enemy.global_position
	_coin_drop_collector.drop_coin(death_position)
	enemy_died.emit(enemy, death_position)


func _on_coin_count_changed(coin_count: int) -> void:
	coin_count_changed.emit(coin_count)


func _on_coin_collected(world_position: Vector2) -> void:
	coin_collected.emit(world_position)


func _on_enemy_escaped(enemy: Enemy) -> void:
	enemy_escaped.emit(enemy)
