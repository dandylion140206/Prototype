@tool
extends Node2D

@export_category("Sphere")
@export_range(20.0, 500.0, 1.0) var sphere_radius: float = 180.0
@export_range(0.1, 0.95, 0.01) var surface_spread: float = 0.88

@export_category("Lightning Shape")
@export_range(1, 100, 1) var bolt_count: int = 10
@export_range(3, 24, 1) var segment_count: int = 9
@export_range(0.05, 1.2, 0.01) var min_length: float = 0.25
@export_range(0.05, 1.2, 0.01) var max_length: float = 0.65
@export_range(0.0, 0.2, 0.001) var surface_jitter: float = 0.035

@export_category("Animation")
@export_range(0.01, 0.3, 0.005) var refresh_interval: float = 0.065
@export_range(0.0, 1.0, 0.01) var active_probability: float = 0.62

@export_category("Appearance")
@export_range(0.5, 20.0, 0.1) var glow_width: float = 8.0
@export_range(0.5, 10.0, 0.1) var core_width: float = 1.8
@export var glow_color: Color = Color(1.0, 0.72, 0.05, 0.32)
@export var core_color: Color = Color(1.0, 1.0, 0.55, 1.0)

var glow_lines: Array[Line2D] = []
var core_lines: Array[Line2D] = []
var additive_material: CanvasItemMaterial = CanvasItemMaterial.new()
var elapsed: float = 0.0
var last_generated_depth: float = 1.0

func _ready() -> void:
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sync_line_count()
	update_lightning()

func _process(delta: float) -> void:
	sync_line_count()
	elapsed += delta

	if elapsed >= refresh_interval:
		elapsed = 0.0
		update_lightning()

func sync_line_count() -> void:
	while glow_lines.size() < bolt_count:
		var glow: Line2D = create_line(glow_width, glow_color)
		var core: Line2D = create_line(core_width, core_color)

		add_child(glow)
		add_child(core)

		glow_lines.append(glow)
		core_lines.append(core)

	while glow_lines.size() > bolt_count:
		var last_index: int = glow_lines.size() - 1
		var glow: Line2D = glow_lines[last_index]
		var core: Line2D = core_lines[last_index]

		glow_lines.remove_at(last_index)
		core_lines.remove_at(last_index)

		if is_instance_valid(glow):
			glow.queue_free()

		if is_instance_valid(core):
			core.queue_free()

func create_line(width_value: float, color_value: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = width_value
	line.default_color = color_value
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.material = additive_material
	return line

func update_lightning() -> void:
	var line_count: int = mini(glow_lines.size(), core_lines.size())

	for i in range(line_count):
		var glow: Line2D = glow_lines[i]
		var core: Line2D = core_lines[i]
		var active: bool = randf() <= active_probability

		glow.visible = active
		core.visible = active

		if not active:
			continue

		var points: PackedVector2Array = create_surface_arc()
		var depth: float = last_generated_depth
		var flicker: float = randf_range(0.65, 1.0)

		glow.points = points
		core.points = points

		glow.width = glow_width * lerpf(0.65, 1.0, depth)
		core.width = core_width * lerpf(0.65, 1.0, depth)

		glow.default_color = glow_color
		core.default_color = core_color

		glow.modulate.a = flicker * lerpf(0.45, 1.0, depth)
		core.modulate.a = flicker * lerpf(0.55, 1.0, depth)

func create_surface_arc() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var center_normal: Vector3 = random_front_normal()
	var tangent: Vector3 = create_random_tangent(center_normal)
	var side: Vector3 = center_normal.cross(tangent).normalized()

	var actual_min_length: float = minf(min_length, max_length)
	var actual_max_length: float = maxf(min_length, max_length)
	var arc_length: float = randf_range(actual_min_length, actual_max_length)
	var depth_sum: float = 0.0

	for i in range(segment_count + 1):
		var progress: float = float(i) / float(segment_count)
		var arc_angle: float = lerpf(
			-arc_length * 0.5,
			arc_length * 0.5,
			progress
		)

		# 仮想的な3D球面上を進める
		var surface_normal: Vector3 = center_normal * cos(arc_angle)
		surface_normal += tangent * sin(arc_angle)

		# 雷らしい不規則な折れを追加する
		if i > 0 and i < segment_count:
			var tangent_offset: float = randf_range(
				-surface_jitter,
				surface_jitter
			)

			var side_offset: float = randf_range(
				-surface_jitter,
				surface_jitter
			)

			surface_normal += tangent * tangent_offset
			surface_normal += side * side_offset

		# 球面上に戻す
		surface_normal = surface_normal.normalized()

		# 裏側に回り込まないよう、前面半球に制限する
		surface_normal.z = maxf(surface_normal.z, 0.02)
		surface_normal = surface_normal.normalized()

		# 3D球面からXYを取り出して2Dへ投影する
		var point_2d: Vector2 = Vector2(
			surface_normal.x,
			surface_normal.y
		)

		points.append(point_2d * sphere_radius)
		depth_sum += clampf(surface_normal.z, 0.0, 1.0)

	last_generated_depth = depth_sum / float(segment_count + 1)
	return points

func random_front_normal() -> Vector3:
	# sqrt(randf())で球面上の発生位置が中央に偏るのを抑える
	var distance: float = sqrt(randf()) * surface_spread
	var angle: float = randf_range(0.0, TAU)

	var x: float = cos(angle) * distance
	var y: float = sin(angle) * distance
	var z_squared: float = maxf(0.0, 1.0 - x * x - y * y)
	var z: float = sqrt(z_squared)

	return Vector3(x, y, z).normalized()

func create_random_tangent(normal: Vector3) -> Vector3:
	var tangent: Vector3 = normal.cross(Vector3.FORWARD)

	# 球面の正面付近では外積がほぼゼロになるため補正する
	if tangent.length_squared() < 0.001:
		tangent = Vector3.RIGHT

	tangent = tangent.normalized()

	var rotation_angle: float = randf_range(0.0, TAU)
	return tangent.rotated(normal, rotation_angle)
