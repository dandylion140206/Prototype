extends Node2D

@onready var _input_controller: WanderingTestInputController = $Controllers/InputController
@onready var _ball: Ball = $Gameplay/Ball
@onready var _combo_radial_ability: ComboRadialAbility = $Gameplay/ComboRadialAbility
@onready var _combo_label: Label = %ComboLabel
@onready var _wandering_enemy_system: WanderingEnemySystem = (
	$Gameplay/WanderingEnemySystem
)
@onready var _audio_manager: WanderingTestAudioManager = $AudioManager
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_shake: CameraShake = %CameraShake
@onready var _impact_camera_shake: ImpactCameraShake = %ImpactCameraShake
@onready var _enemy_health_bar_layer: EnemyHealthBarLayer = %EnemyHealthBarLayer


func _ready() -> void:
	_camera_shake.setup(_camera)
	_impact_camera_shake.setup(_camera_shake)
	_combo_radial_ability.combo_changed.connect(_on_combo_changed)
	_combo_radial_ability.activated.connect(_on_radial_ability_activated)
	_combo_radial_ability.hit_landed.connect(_audio_manager.play_radial_hit)
	_combo_radial_ability.setup(_ball)
	_ball.hit_landed.connect(_on_ball_hit_landed)
	_input_controller.active_ability_requested.connect(_ball.request_ability_activation)
	_input_controller.secondary_ability_requested.connect(_combo_radial_ability.try_activate)
	_wandering_enemy_system.enemy_spawned.connect(_enemy_health_bar_layer.add_enemy)
	_wandering_enemy_system.enemy_died.connect(_audio_manager.play_enemy_death)

	var mouse_position := get_global_mouse_position()
	_ball.global_position = mouse_position
	_ball.set_target_position(mouse_position)


func _process(_delta: float) -> void:
	_combo_label.global_position = (
		_ball.get_interpolated_global_position()
		+ Vector2(-68.0, -82.0)
	)


func _physics_process(_delta: float) -> void:
	_ball.set_target_position(get_global_mouse_position())


func _on_ball_hit_landed(hit_data: HitData) -> void:
	_combo_radial_ability.register_ball_hit()
	_impact_camera_shake.apply_hit(hit_data)
	_audio_manager.play_ball_hit(hit_data, _combo_radial_ability.get_combo_count())


func _on_radial_ability_activated(impact_data: HitData) -> void:
	_impact_camera_shake.apply_hit(impact_data)
	_audio_manager.play_radial_activation(impact_data.impact_position)


func _on_combo_changed(combo_count: int) -> void:
	_combo_label.text = "COMBO %d" % combo_count
