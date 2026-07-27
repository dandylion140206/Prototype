class_name CameraShake
extends Node

@export var max_offset: Vector2 = Vector2(20.0, 12.0)
@export_range(0.0, 5.0, 0.1) var max_rotation_degrees: float = 0.0
@export_range(0.0, 10.0, 0.1) var trauma_decay_rate: float = 3.0
@export_range(1.0, 4.0, 0.1) var trauma_power: float = 2.0
@export_range(0.0, 100.0, 1.0) var noise_speed: float = 30.0
@export_range(0.0, 0.5, 0.01) var trauma_dead_zone: float = 0.1

var _camera: Camera2D
var _base_offset: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _trauma: float = 0.0
var _noise_position: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()


func _process(delta: float) -> void:
	if _camera == null:
		return

	if _trauma <= trauma_dead_zone:
		_trauma = 0.0
		_reset_camera_transform()
		return

	_noise_position += noise_speed * delta

	var shake_strength := pow(_trauma, trauma_power)
	var noise_x := _noise.get_noise_1d(_noise_position)
	var noise_y := _noise.get_noise_1d(_noise_position + 1000.0)
	var rotation_noise := _noise.get_noise_1d(_noise_position + 2000.0)

	_camera.offset = (
		_base_offset
		+ Vector2(
			noise_x * max_offset.x,
			noise_y * max_offset.y
		) * shake_strength
	)

	_camera.rotation = (
		_base_rotation
		+ deg_to_rad(max_rotation_degrees)
		* rotation_noise
		* shake_strength
	)

	_trauma = maxf(_trauma - trauma_decay_rate * delta, 0.0)

	if _trauma <= trauma_dead_zone:
		_trauma = 0.0
		_reset_camera_transform()


func _exit_tree() -> void:
	if not is_instance_valid(_camera):
		return

	_camera.offset = _base_offset
	_camera.rotation = _base_rotation


func setup(camera: Camera2D) -> void:
	assert(camera != null, "camera must not be null.")

	_camera = camera
	_base_offset = _camera.offset
	_base_rotation = _camera.rotation

	var random := RandomNumberGenerator.new()
	random.randomize()

	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.seed = random.randi_range(0, 2147483647)


func add_trauma(amount: float) -> void:
	assert(_camera != null, "CameraShake must be setup before add_trauma().")
	assert(amount >= 0.0, "amount must not be negative.")

	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func stop() -> void:
	_trauma = 0.0
	_noise_position = 0.0
	_reset_camera_transform()


func _reset_camera_transform() -> void:
	if _camera == null:
		return

	_camera.offset = _base_offset
	_camera.rotation = _base_rotation
