class_name CoinRaidController
extends Node

signal enemy_escaped(enemy: Enemy)

const ENEMY_MOTION_MODIFIER_RESOURCE = preload("res://game/enemy/enemy_motion_modifier.gd")
const ESCAPE_TARGET_PADDING: float = 10.0

@export var carried_coin_scene: PackedScene

@export_group("Carry")
@export_range(0.0, 10.0, 0.01, "or_greater") var carry_speed_multiplier: float = 0.65
@export_range(0.01, 10.0, 0.01, "or_greater") var carry_mass_multiplier: float = 2.0
@export var carried_coin_offset: Vector2 = Vector2.ZERO

var _coin_inventory: CoinInventory
var _approach_target_provider: CoinApproachTargetProvider
var _raid_area: CoinRaidArea
var _enemy_escape_line: LineSegment2D
var _carry_modifier: ENEMY_MOTION_MODIFIER_RESOURCE
var _raid_states: Dictionary[Enemy, EnemyRaidState] = {}


func _ready() -> void:
	_carry_modifier = ENEMY_MOTION_MODIFIER_RESOURCE.new()
	_carry_modifier.speed_multiplier = carry_speed_multiplier
	_carry_modifier.mass_multiplier = carry_mass_multiplier
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	for enemy_value: Variant in _raid_states.keys():
		var enemy := enemy_value as Enemy
		if not is_instance_valid(enemy):
			_raid_states.erase(enemy)
			continue

		var state := _raid_states[enemy]
		match state.phase:
			EnemyRaidState.RaidPhase.APPROACHING:
				_process_approaching(enemy, state)
			EnemyRaidState.RaidPhase.CARRYING:
				_process_carrying(enemy, state)


func setup(
	coin_inventory: CoinInventory,
	approach_target_provider: CoinApproachTargetProvider,
	raid_area: CoinRaidArea,
	enemy_escape_line: LineSegment2D
) -> void:
	assert(coin_inventory != null, "coin_inventory must not be null.")
	assert(approach_target_provider != null, "approach_target_provider must not be null.")
	assert(raid_area != null, "raid_area must not be null.")
	assert(enemy_escape_line != null, "enemy_escape_line must not be null.")
	assert(carried_coin_scene != null, "carried_coin_scene must not be null.")

	_coin_inventory = coin_inventory
	_approach_target_provider = approach_target_provider
	_raid_area = raid_area
	_enemy_escape_line = enemy_escape_line
	set_physics_process(true)


func register_enemy(enemy: Enemy) -> void:
	assert(enemy != null, "enemy must not be null.")
	assert(_coin_inventory != null, "setup must be called before registering enemies.")

	if _raid_states.has(enemy):
		return

	var state := EnemyRaidState.new()
	state.approach_target = _approach_target_provider.assign_target(enemy)
	state.approach_ratio = _approach_target_provider.get_target_ratio(enemy)
	state.has_approach_target = true
	_raid_states[enemy] = state

	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))
	enemy.set_destination(state.approach_target)


func get_approaching_enemy_count() -> int:
	return _count_phase(EnemyRaidState.RaidPhase.APPROACHING)


func get_carrying_enemy_count() -> int:
	return _count_phase(EnemyRaidState.RaidPhase.CARRYING)


func _process_approaching(enemy: Enemy, state: EnemyRaidState) -> void:
	if not _raid_area.is_global_position_inside(enemy.global_position):
		return

	if _coin_inventory.try_take_coin():
		_start_carrying(enemy, state)


func _process_carrying(enemy: Enemy, state: EnemyRaidState) -> void:
	if _enemy_escape_line.has_global_point_crossed_outward(enemy.global_position):
		_complete_raid(enemy, state)
		return

	_update_escape_destination(enemy, state)


func _start_carrying(enemy: Enemy, state: EnemyRaidState) -> void:
	_release_approach_target(enemy, state)
	state.phase = EnemyRaidState.RaidPhase.CARRYING
	state.is_carrying_coin = true
	state.motion_modifier_id = enemy.add_motion_modifier(_carry_modifier)
	state.carried_coin_visual = _create_carried_visual(enemy)
	_update_escape_destination(enemy, state)


func _complete_raid(enemy: Enemy, state: EnemyRaidState) -> void:
	state.phase = EnemyRaidState.RaidPhase.ESCAPED
	_remove_raid_state(enemy)
	enemy_escaped.emit(enemy)
	enemy.queue_free()


func _remove_raid_state(enemy: Enemy) -> void:
	if not _raid_states.has(enemy):
		return

	var state := _raid_states[enemy]
	_raid_states.erase(enemy)
	_release_approach_target(enemy, state)

	if state.motion_modifier_id >= 0:
		enemy.remove_motion_modifier(state.motion_modifier_id)

	if is_instance_valid(state.carried_coin_visual):
		state.carried_coin_visual.queue_free()


func _release_approach_target(enemy: Enemy, state: EnemyRaidState) -> void:
	if not state.has_approach_target:
		return

	_approach_target_provider.release_target(enemy)
	state.has_approach_target = false


func _create_carried_visual(enemy: Enemy) -> Node2D:
	var carried_visual := carried_coin_scene.instantiate() as Node2D
	if carried_visual == null:
		push_error("carried_coin_scene root must be Node2D.")
		return null

	enemy.add_child(carried_visual)
	carried_visual.position = carried_coin_offset
	carried_visual.z_index = 1

	return carried_visual


func _update_escape_destination(enemy: Enemy, state: EnemyRaidState) -> void:
	var destination := _enemy_escape_line.get_global_point_at_ratio(
		state.approach_ratio,
		ESCAPE_TARGET_PADDING
	)
	enemy.set_destination(destination)


func _count_phase(phase: EnemyRaidState.RaidPhase) -> int:
	var count := 0

	for state_value: Variant in _raid_states.values():
		var state := state_value as EnemyRaidState
		if state.phase == phase:
			count += 1

	return count


func _on_enemy_died(enemy: Enemy) -> void:
	_remove_raid_state(enemy)


func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	_remove_raid_state(enemy)
