extends Node2D

@onready var _input_controller: InputController = $InputController
@onready var _ball: Ball = $Ball
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_shake: CameraShake = %CameraShake
@onready var _impact_camera_shake: ImpactCameraShake = %ImpactCameraShake
@onready var _enemy_spawner: EnemySpawner = $EnemySpawner
@onready var _enemy_crowd_system: EnemyCrowdSystem = $EnemyCrowdSystem
@onready var _enemy_health_bar_layer: EnemyHealthBarLayer = %EnemyHealthBarLayer


func _ready() -> void:
	_camera_shake.setup(_camera)
	_impact_camera_shake.setup(_camera_shake)

	_ball.hit_landed.connect(_impact_camera_shake.apply_hit)
	_input_controller.active_ability_requested.connect(
		_ball.request_active_ability
	)
	_enemy_spawner.enemy_spawned.connect(_enemy_crowd_system.register)
	_enemy_spawner.enemy_spawned.connect(_enemy_health_bar_layer.add_enemy)

	_ball.set_target_position(get_global_mouse_position())


func _physics_process(_delta: float) -> void:
	_ball.set_target_position(get_global_mouse_position())
