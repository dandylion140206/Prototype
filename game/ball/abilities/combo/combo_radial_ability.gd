class_name ComboRadialAbility
extends Node2D

signal activated(impact_data: HitData)
signal hit_landed(hit_data: HitData)
signal combo_changed(combo_count: int)
signal audio_requested(request: AudioRequest)

@export_group("Combo")
@export_range(0.0, 5.0, 0.01) var combo_timeout: float = 0.3
@export_range(1, 100, 1) var max_combo: int = 10

@export_group("Attack")
@export_range(0.0, 1000.0, 1.0) var base_radius: float = 40.0
@export_range(0.0, 100.0, 1.0) var radius_per_combo: float = 5.0
@export_range(0.0, 1000.0, 1.0) var base_damage: float = 5.0
@export_range(0.0, 1000.0, 1.0) var damage_per_combo: float = 5.0
@export_range(0.0, 10000.0, 10.0) var impact_speed: float = 2500.0
@export_range(0.01, 1.0, 0.01) var expansion_duration: float = 0.15
@export_range(0.0, 5.0, 0.01) var cooldown: float = 0.5
@export_flags_2d_physics var collision_mask: int = 2
@export_range(1, 512, 1) var max_query_results: int = 256

@export_group("Audio")
@export var radial_activation_audio_cue: AudioCue
@export var radial_hit_audio_cue: AudioCue
@export var combo_hit_audio_cue: AudioCue

var _attack_source: Node2D
var _combo_count: int = 0
var _last_combo_hit_time: float = -INF
var _last_combo_physics_frame: int = -1
var _is_attack_active: bool = false
var _attack_position: Vector2 = Vector2.ZERO
var _attack_radius: float = 0.0
var _attack_damage: float = 0.0
var _attack_elapsed_time: float = 0.0
var _hit_hurtbox_ids: Dictionary[int, bool] = {}

@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _visual: RadialAttackVisual = $RadialAttackVisual


func _ready() -> void:
	_cooldown_timer.one_shot = true


func _process(_delta: float) -> void:
	if _combo_count == 0:
		return

	if _get_current_time() - _last_combo_hit_time < combo_timeout:
		return

	_reset_combo()


func _physics_process(delta: float) -> void:
	if not _is_attack_active:
		return

	_attack_elapsed_time = minf(_attack_elapsed_time + delta, expansion_duration)

	var linear_progress := _attack_elapsed_time / expansion_duration
	var eased_progress := 1.0 - pow(1.0 - linear_progress, 3.0)
	var current_radius := _attack_radius * eased_progress

	_visual.set_radius(current_radius)
	_apply_hits_at_radius(current_radius)

	if _attack_elapsed_time >= expansion_duration:
		_finish_attack()


func setup(attack_source: Node2D) -> void:
	assert(attack_source != null, "attack_source must not be null.")
	assert(radial_activation_audio_cue != null, "radial_activation_audio_cue must not be null.")
	assert(radial_hit_audio_cue != null, "radial_hit_audio_cue must not be null.")
	assert(combo_hit_audio_cue != null, "combo_hit_audio_cue must not be null.")
	assert(combo_timeout >= 0.0, "combo_timeout must not be negative.")
	assert(max_combo > 0, "max_combo must be positive.")
	assert(base_radius >= 0.0, "base_radius must not be negative.")
	assert(radius_per_combo >= 0.0, "radius_per_combo must not be negative.")
	assert(base_damage >= 0.0, "base_damage must not be negative.")
	assert(damage_per_combo >= 0.0, "damage_per_combo must not be negative.")
	assert(impact_speed >= 0.0, "impact_speed must not be negative.")
	assert(expansion_duration > 0.0, "expansion_duration must be greater than 0.0.")
	assert(cooldown >= 0.0, "cooldown must not be negative.")
	assert(max_query_results > 0, "max_query_results must be positive.")

	_attack_source = attack_source
	combo_changed.emit(_combo_count)


func register_ball_hit(hit_data: HitData) -> void:
	assert(_attack_source != null, "ComboRadialAbility must be setup before registering hits.")
	assert(hit_data != null, "hit_data must not be null.")

	var physics_frame := Engine.get_physics_frames()
	if physics_frame == _last_combo_physics_frame:
		return

	var current_time := _get_current_time()
	if current_time - _last_combo_hit_time >= combo_timeout:
		_combo_count = 0

	_last_combo_physics_frame = physics_frame
	_last_combo_hit_time = current_time

	var next_combo := mini(_combo_count + 1, max_combo)
	if next_combo != _combo_count:
		_combo_count = next_combo
		combo_changed.emit(_combo_count)

	var audio_request := AudioRequest.new(
		combo_hit_audio_cue,
		hit_data.impact_position,
		hit_data.attack_source_id,
		maxi(_combo_count - 1, 0)
	)
	audio_requested.emit(audio_request)


func try_activate() -> bool:
	assert(_attack_source != null, "ComboRadialAbility must be setup before try_activate().")

	if _is_attack_active or not _cooldown_timer.is_stopped():
		return false

	var consumed_combo := _get_active_combo()
	_start_attack(
		_attack_source.global_position,
		base_radius + radius_per_combo * consumed_combo,
		base_damage + damage_per_combo * consumed_combo
	)

	if cooldown > 0.0:
		_cooldown_timer.start(cooldown)

	var activation_data := HitData.new(
		0.0,
		Vector2.RIGHT * impact_speed,
		_attack_position,
		0,
		0,
		get_instance_id()
	)
	activated.emit(activation_data)

	var audio_request := AudioRequest.new(
		radial_activation_audio_cue,
		_attack_position,
		get_instance_id()
	)
	audio_requested.emit(audio_request)
	_reset_combo()

	return true


func get_combo_count() -> int:
	return _get_active_combo()


func _start_attack(attack_position: Vector2, attack_radius: float, damage: float) -> void:
	global_position = attack_position
	_attack_position = attack_position
	_attack_radius = attack_radius
	_attack_damage = damage
	_attack_elapsed_time = 0.0
	_hit_hurtbox_ids.clear()
	_is_attack_active = true
	_visual.start()


func _finish_attack() -> void:
	_is_attack_active = false
	_visual.finish()


func _apply_hits_at_radius(current_radius: float) -> void:
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = current_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0.0, _attack_position)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results := get_world_2d().direct_space_state.intersect_shape(query, max_query_results)

	for result in results:
		var hurtbox := result.collider as Hurtbox
		if hurtbox == null or hurtbox.is_queued_for_deletion():
			continue

		var hurtbox_id := hurtbox.get_instance_id()
		if _hit_hurtbox_ids.has(hurtbox_id):
			continue

		_hit_hurtbox_ids[hurtbox_id] = true

		var direction := (hurtbox.global_position - _attack_position).normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT

		var hit_data := HitData.new(
			_attack_damage,
			direction * impact_speed,
			_attack_position,
			0,
			0,
			get_instance_id()
		)

		if hurtbox.receive_hit(hit_data):
			hit_landed.emit(hit_data)
			var audio_request := AudioRequest.new(
				radial_hit_audio_cue,
				hurtbox.global_position,
				hit_data.attack_source_id
			)
			audio_requested.emit(audio_request)


func _get_active_combo() -> int:
	if _combo_count == 0:
		return 0

	if _get_current_time() - _last_combo_hit_time >= combo_timeout:
		_reset_combo()

	return _combo_count


func _reset_combo() -> void:
	if _combo_count == 0:
		return

	_combo_count = 0
	_last_combo_hit_time = -INF
	_last_combo_physics_frame = -1
	combo_changed.emit(_combo_count)


func _get_current_time() -> float:
	return Time.get_ticks_msec() * 0.001
