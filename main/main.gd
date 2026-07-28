extends Node2D

@onready var _input_controller: InputController = $InputController
@onready var _ball: Ball = $Ball
@onready var _audio_manager: AudioManager = $AudioManager
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_target_follow: CameraTargetFollow = $Camera2D/CameraTargetFollow
@onready var _camera_shake: CameraShake = %CameraShake
@onready var _impact_camera_shake: ImpactCameraShake = %ImpactCameraShake
@onready var _enemy_spawner: EnemySpawner = $EnemySpawner
@onready var _enemy_crowd_system: EnemyCrowdSystem = $EnemyCrowdSystem
@onready var _enemy_health_bar_layer: EnemyHealthBarLayer = %EnemyHealthBarLayer
@onready var _coin_system: CoinSystem = $CoinSystem
@onready var _coin_raid_system: CoinRaidSystem = $CoinRaidSystem


func _ready() -> void:
	_camera_target_follow.setup(
		_camera,
		Callable(_ball, "get_interpolated_global_position"),
		Callable(_ball, "get_velocity")
	)
	_camera_shake.setup(_camera)
	_impact_camera_shake.setup(_camera_shake)
	_coin_raid_system.setup(_coin_system)
	_ball.hit_landed.connect(_impact_camera_shake.apply_hit)
	_ball.hit_landed.connect(_audio_manager.play_hit)
	_input_controller.active_ability_requested.connect(_ball.request_ability_activation)
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_coin_system.coin_collected.connect(_audio_manager.play_coin_collect)

	var mouse_position := get_global_mouse_position()
	_ball.global_position = mouse_position
	_ball.set_target_position(mouse_position)


func _physics_process(_delta: float) -> void:
	_ball.set_target_position(get_global_mouse_position())


func _on_enemy_spawned(enemy: Enemy) -> void:
	_enemy_crowd_system.register(enemy.get_crowd_agent())
	_enemy_health_bar_layer.add_enemy(enemy)
	_coin_raid_system.register_enemy(enemy)
	enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_enemy_died(enemy: Enemy) -> void:
	_audio_manager.play_enemy_death(enemy.global_position)
	_coin_system.drop_coin(enemy.global_position)
