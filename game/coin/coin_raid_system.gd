class_name CoinRaidSystem
extends Node

const ENEMY_MOTION_MODIFIER_RESOURCE = preload("res://game/enemy/enemy_motion_modifier.gd")
const ESCAPE_TARGET_PADDING: float = 10.0

@export var carried_coin_scene: PackedScene

@export_group("Raid")
@export_range(0.0, 1000.0, 1.0) var steal_distance: float = 72.0
@export_range(0.0, 1000.0, 1.0) var escape_margin: float = 40.0

@export_group("Carry")
@export_range(0.0, 10.0, 0.01, "or_greater") var carry_speed_multiplier: float = 0.65
@export_range(0.01, 10.0, 0.01, "or_greater") var carry_mass_multiplier: float = 2.0
@export var carried_coin_offset: Vector2 = Vector2.ZERO

var _coin_system: CoinSystem
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
			if _is_fully_outside_viewport(enemy.global_position):
				_complete_raid(enemy)
			continue

		if enemy.global_position.distance_squared_to(_coin_system.get_coin_box_global_position()) > steal_distance * steal_distance:
			continue

		if _coin_system.try_take_coin():
			_start_carrying(enemy, data)


func setup(coin_system: CoinSystem) -> void:
	assert(coin_system != null, "coin_system must not be null.")
	assert(carried_coin_scene != null, "carried_coin_scene must not be null.")

	_coin_system = coin_system
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
	data.is_carrying = true
	data.modifier_id = enemy.add_motion_modifier(_carry_modifier)
	data.carried_visual = _create_carried_visual(enemy)
	enemy.set_destination(_get_nearest_escape_position(enemy.global_position))


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


func _get_nearest_escape_position(world_position: Vector2) -> Vector2:
	var viewport := get_viewport()
	var viewport_rect := viewport.get_visible_rect()
	var canvas_transform := viewport.get_canvas_transform()
	var screen_position := canvas_transform * world_position

	var left_distance := absf(screen_position.x - viewport_rect.position.x)
	var right_distance := absf(viewport_rect.end.x - screen_position.x)
	var top_distance := absf(screen_position.y - viewport_rect.position.y)
	var bottom_distance := absf(viewport_rect.end.y - screen_position.y)
	var minimum_distance := minf(
		minf(left_distance, right_distance),
		minf(top_distance, bottom_distance)
	)
	var target_screen_position := screen_position
	var target_offset := escape_margin + ESCAPE_TARGET_PADDING

	if minimum_distance == left_distance:
		target_screen_position.x = viewport_rect.position.x - target_offset
	elif minimum_distance == right_distance:
		target_screen_position.x = viewport_rect.end.x + target_offset
	elif minimum_distance == top_distance:
		target_screen_position.y = viewport_rect.position.y - target_offset
	else:
		target_screen_position.y = viewport_rect.end.y + target_offset

	return canvas_transform.affine_inverse() * target_screen_position


func _is_fully_outside_viewport(world_position: Vector2) -> bool:
	var viewport := get_viewport()
	var screen_position := viewport.get_canvas_transform() * world_position
	return not viewport.get_visible_rect().grow(escape_margin).has_point(screen_position)


class RaidData:
	var is_carrying: bool = false
	var modifier_id: int = -1
	var carried_visual: Node2D
