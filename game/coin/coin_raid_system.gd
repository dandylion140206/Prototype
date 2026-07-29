class_name CoinRaidSystem
extends Node

const ENEMY_MOTION_MODIFIER_RESOURCE = preload("res://game/enemy/enemy_motion_modifier.gd")
const EXIT_TARGET_PADDING: float = 10.0

@export var carried_coin_scene: PackedScene

@export_group("Carry")
@export_range(0.0, 10.0, 0.01, "or_greater") var carry_speed_multiplier: float = 0.65
@export_range(0.01, 10.0, 0.01, "or_greater") var carry_mass_multiplier: float = 2.0
@export var carried_coin_offset: Vector2 = Vector2.ZERO

var _coin_system: CoinSystem
var _exit_lines: Array[LineSegment2D] = []
var _carry_modifier: ENEMY_MOTION_MODIFIER_RESOURCE
var _raid_data: Dictionary[Enemy, RaidData] = {}


func _ready() -> void:
	_carry_modifier = ENEMY_MOTION_MODIFIER_RESOURCE.new()
	_carry_modifier.speed_multiplier = carry_speed_multiplier
	_carry_modifier.mass_multiplier = carry_mass_multiplier
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	for enemy_value: Variant in _raid_data.keys():
		var enemy := enemy_value as Enemy
		if not is_instance_valid(enemy):
			_raid_data.erase(enemy)
			continue

		var data := _raid_data[enemy]
		if data.is_carrying:
			if data.exit_line.has_global_point_crossed_outward(enemy.global_position):
				_complete_raid(enemy)
			else:
				_update_exit_destination(enemy, data)
			continue

		if not _coin_system.is_global_position_inside(enemy.global_position):
			continue

		if _coin_system.try_take_coin():
			_start_carrying(enemy, data)


func setup(coin_system: CoinSystem, exit_lines: Array[LineSegment2D]) -> void:
	assert(coin_system != null, "coin_system must not be null.")
	assert(not exit_lines.is_empty(), "exit_lines must not be empty.")
	assert(carried_coin_scene != null, "carried_coin_scene must not be null.")
	for exit_line in exit_lines:
		assert(exit_line != null, "exit_lines must not contain null.")

	_coin_system = coin_system
	_exit_lines = exit_lines
	set_physics_process(true)


func register_enemy(enemy: Enemy) -> void:
	assert(enemy != null, "enemy must not be null.")
	assert(_coin_system != null, "setup must be called before registering enemies.")

	if _raid_data.has(enemy):
		return

	_raid_data[enemy] = RaidData.new()
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))
	enemy.set_destination(_coin_system.get_coin_box_global_position())


func _on_enemy_died(enemy: Enemy) -> void:
	if not _raid_data.has(enemy):
		return

	var return_position := enemy.global_position
	var data := _raid_data[enemy]
	var was_carrying := data.is_carrying
	_remove_raid_data(enemy)

	if was_carrying:
		_coin_system.drop_coin(return_position)


func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	if _raid_data.has(enemy):
		_remove_raid_data(enemy)


func _start_carrying(enemy: Enemy, data: RaidData) -> void:
	data.exit_line = _get_nearest_exit_line(enemy.global_position)
	data.is_carrying = true
	data.modifier_id = enemy.add_motion_modifier(_carry_modifier)
	data.carried_visual = _create_carried_visual(enemy)
	_update_exit_destination(enemy, data)


func _complete_raid(enemy: Enemy) -> void:
	_remove_raid_data(enemy)
	enemy.queue_free()


func _remove_raid_data(enemy: Enemy) -> void:
	var data := _raid_data[enemy]
	_raid_data.erase(enemy)

	if data.modifier_id >= 0:
		enemy.remove_motion_modifier(data.modifier_id)

	if is_instance_valid(data.carried_visual):
		data.carried_visual.queue_free()


func _create_carried_visual(enemy: Enemy) -> Node2D:
	var carried_visual := carried_coin_scene.instantiate() as Node2D
	if carried_visual == null:
		push_error("carried_coin_scene root must be Node2D.")
		return null

	enemy.add_child(carried_visual)
	carried_visual.position = carried_coin_offset
	carried_visual.z_index = 1

	return carried_visual


func _get_nearest_exit_line(world_position: Vector2) -> LineSegment2D:
	var nearest_line := _exit_lines[0]
	var nearest_position := nearest_line.get_closest_global_point(world_position)
	var nearest_distance_squared := world_position.distance_squared_to(nearest_position)

	for index in range(1, _exit_lines.size()):
		var exit_line := _exit_lines[index]
		var exit_position := exit_line.get_closest_global_point(world_position)
		var distance_squared := world_position.distance_squared_to(exit_position)
		if distance_squared >= nearest_distance_squared:
			continue

		nearest_line = exit_line
		nearest_distance_squared = distance_squared

	return nearest_line


func _update_exit_destination(enemy: Enemy, data: RaidData) -> void:
	var destination := data.exit_line.get_closest_global_point(
		enemy.global_position,
		EXIT_TARGET_PADDING
	)
	enemy.set_destination(destination)


class RaidData:
	var is_carrying: bool = false
	var modifier_id: int = -1
	var carried_visual: Node2D
	var exit_line: LineSegment2D
