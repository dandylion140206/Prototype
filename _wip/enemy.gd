class_name SoftEnemy
extends Node2D

## 放浪・追従・停止で移動する敵。移動モードの切り替えは外部から指示する。

enum MovementMode {
	IDLE,
	WANDER,
	CHASE,
}

@export var initial_movement_mode: MovementMode = MovementMode.IDLE
@export_range(0.0, 1000.0, 10.0) var wander_speed: float = 40.0
@export_range(0.0, 1000.0, 10.0) var chase_speed: float = 90.0

## 放浪範囲。グローバル座標で指定する。
@export var wander_area: Rect2 = Rect2(-128.0, -128.0, 256.0, 256.0):
	set(value):
		wander_area = value
		if is_node_ready():
			_wander_provider.area = value

@export var chase_target: Node2D = null:
	set(value):
		chase_target = value
		if is_node_ready():
			_chase_provider.target = value

var _movement_mode: MovementMode = MovementMode.IDLE
var _mode_before_knockback: MovementMode = MovementMode.IDLE
var _active_provider: DestinationProvider = null

@onready var _wander_provider: WanderProvider = $WanderProvider
@onready var _chase_provider: ChaseProvider = $ChaseProvider
@onready var _seeker: DestinationSeeker = $Seeker
@onready var _knockback: Knockback = $Knockback
@onready var _separation: Separation = $Separation


func _ready() -> void:
	_wander_provider.area = wander_area
	_chase_provider.target = chase_target

	_wander_provider.destination_changed.connect(_on_destination_changed)
	_chase_provider.destination_changed.connect(_on_destination_changed)
	_chase_provider.target_lost.connect(_on_chase_target_lost)
	_seeker.destination_reached.connect(_on_destination_reached)
	_knockback.knockback_finished.connect(_on_knockback_finished)

	_apply_movement_mode(initial_movement_mode)


func _physics_process(delta: float) -> void:
	_separation.update()

	var velocity := _seeker.update(global_position, delta) + _knockback.velocity
	velocity += _separation.get_push_velocity()

	global_position += velocity * delta + _separation.get_position_correction()


func get_movement_mode() -> MovementMode:
	return _movement_mode


func set_movement_mode(mode: MovementMode) -> void:
	# NOTE: ノックバック中の指示は、復帰先のモードとして扱う。
	if _knockback.is_knocked_back():
		_mode_before_knockback = mode
		return

	_apply_movement_mode(mode)


func apply_knockback(impulse: Vector2) -> void:
	if not _knockback.is_knocked_back():
		_mode_before_knockback = _movement_mode

	_apply_movement_mode(MovementMode.IDLE)
	_knockback.start(impulse)


func _on_destination_changed(destination: Vector2) -> void:
	_seeker.set_destination(destination)


func _on_destination_reached() -> void:
	if _active_provider != null:
		_active_provider.notify_arrived()


func _on_chase_target_lost() -> void:
	_apply_movement_mode(MovementMode.WANDER)


func _on_knockback_finished() -> void:
	_apply_movement_mode(_mode_before_knockback)


func _apply_movement_mode(mode: MovementMode) -> void:
	if _active_provider != null:
		_active_provider.deactivate()

	_movement_mode = mode
	_active_provider = null

	match mode:
		MovementMode.IDLE:
			_seeker.stop()
		MovementMode.WANDER:
			_seeker.max_speed = wander_speed
			_active_provider = _wander_provider
		MovementMode.CHASE:
			_seeker.max_speed = chase_speed
			_active_provider = _chase_provider

	if _active_provider != null:
		_active_provider.activate()
