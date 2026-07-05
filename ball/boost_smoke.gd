class_name BoostSmoke
extends CPUParticles2D

@export_range(0.0, 2.0, 0.01) var emit_duration: float = 0.32
@export var texture_size: int = 56

var _movement: Movement
var _remaining_time: float = 0.0


func _ready() -> void:
	if texture == null:
		texture = _create_circle_texture(texture_size)

	emitting = false


func _process(delta: float) -> void:
	if _remaining_time <= 0.0:
		return

	_remaining_time -= delta

	_update_direction()

	if _remaining_time <= 0.0:
		emitting = false


func setup(movement: Movement) -> void:
	assert(movement != null, "movement must not be null.")
	_movement = movement


func start_emitting() -> void:
	assert(_movement != null, "movement must be setup before start_emitting().")

	_remaining_time = emit_duration
	_update_direction()
	emitting = true


func _update_direction() -> void:
	var velocity := _movement.get_velocity()

	if velocity.is_zero_approx():
		return

	var emission_direction := -velocity.normalized()
	self.direction = emission_direction


func _create_circle_texture(size: int) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0 - 1.0

	for y in range(size):
		for x in range(size):
			var pixel_position := Vector2(x, y)
			var distance := pixel_position.distance_to(center)

			if distance > radius:
				continue

			var alpha := 1.0 - smoothstep(radius * 0.6, radius, distance)
			var pixel_color := Color(1.0, 1.0, 1.0, alpha)

			image.set_pixel(x, y, pixel_color)

	return ImageTexture.create_from_image(image)
