extends Node2D

@onready var _input_controller: InputController = $Controllers/InputController
@onready var _ball: Ball = $Gameplay/Ball
@onready var _wandering_enemy_system: WanderingEnemySystem = (
	$Gameplay/WanderingEnemySystem
)
@onready var _audio_director: AudioDirector = $AudioDirector
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_shake: CameraShake = %CameraShake
@onready var _impact_camera_shake: ImpactCameraShake = %ImpactCameraShake
@onready var _enemy_health_bar_layer: EnemyHealthBarLayer = %EnemyHealthBarLayer


func _ready() -> void:
	_camera_shake.setup(_camera)
	_impact_camera_shake.setup(_camera_shake)
	_ball.hit_landed.connect(_on_ball_hit_landed)
	_ball.audio_requested.connect(_audio_director.request)
	_ball.shockwave_activated.connect(_on_shockwave_activated)
	_input_controller.primary_ability_requested.connect(_ball.request_primary_ability_activation)
	_input_controller.secondary_ability_requested.connect(_ball.request_secondary_ability_activation)
	_wandering_enemy_system.enemy_spawned.connect(_enemy_health_bar_layer.add_enemy)
	_wandering_enemy_system.audio_requested.connect(_audio_director.request)

	var mouse_position := get_global_mouse_position()
	_ball.global_position = mouse_position
	_ball.set_target_position(mouse_position)


func _physics_process(_delta: float) -> void:
	_ball.set_target_position(get_global_mouse_position())


func _on_ball_hit_landed(hit_data: HitData) -> void:
	_impact_camera_shake.apply_hit(hit_data)


func _on_shockwave_activated(impact_data: HitData) -> void:
	_impact_camera_shake.apply_hit(impact_data)
