extends Node2D

@onready var _input_controller: InputController = $Controllers/InputController
@onready var _ball: Ball = $Gameplay/Ball
@onready var _coin_raid_route: CoinRaidRoute = $Gameplay/CoinRaidRoute
@onready var _audio_manager: AudioManager = $AudioManager
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_shake: CameraShake = %CameraShake
@onready var _impact_camera_shake: ImpactCameraShake = %ImpactCameraShake
@onready var _enemy_health_bar_layer: EnemyHealthBarLayer = %EnemyHealthBarLayer
@onready var _coin_hud: CoinHUD = $ScreenUI/CoinHUD


func _ready() -> void:
	_camera_shake.setup(_camera)
	_impact_camera_shake.setup(_camera_shake)
	_ball.hit_landed.connect(_impact_camera_shake.apply_hit)
	_ball.hit_landed.connect(_audio_manager.play_hit)
	_input_controller.active_ability_requested.connect(_ball.request_ability_activation)
	_coin_raid_route.enemy_spawned.connect(_enemy_health_bar_layer.add_enemy)
	_coin_raid_route.enemy_died.connect(_on_enemy_died)
	_coin_raid_route.coin_collected.connect(_audio_manager.play_coin_collect)
	_coin_raid_route.coin_count_changed.connect(_coin_hud.set_coin_count)
	_coin_hud.setup(_coin_raid_route.get_coin_count())

	var mouse_position := get_global_mouse_position()
	_ball.global_position = mouse_position
	_ball.set_target_position(mouse_position)


func _physics_process(_delta: float) -> void:
	_ball.set_target_position(get_global_mouse_position())


func _on_enemy_died(_enemy: Enemy, world_position: Vector2) -> void:
	_audio_manager.play_enemy_death(world_position)
