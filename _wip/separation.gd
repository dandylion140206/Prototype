class_name Separation
extends Area2D

## 範囲内の他の敵から離れるための速度と位置補正を計算する。
## NOTE: 敵専用のレイヤーを collision_layer と collision_mask の両方に設定して使用する。

@export_range(1.0, 128.0, 1.0) var inner_radius: float = 10.0
@export_range(0.0, 1000.0, 10.0) var max_push_speed: float = 80.0

var _push_velocity: Vector2 = Vector2.ZERO
var _position_correction: Vector2 = Vector2.ZERO

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _outer_radius: float = _get_outer_radius()


func _ready() -> void:
	assert(inner_radius < _outer_radius, "inner_radius は反発範囲の半径より小さい値にしてください。")


## 反発量を計算する。所有者が毎 physics フレーム呼び出す。
func update() -> void:
	_push_velocity = Vector2.ZERO
	_position_correction = Vector2.ZERO

	for area in get_overlapping_areas():
		var offset := global_position - area.global_position
		var distance := offset.length()
		var direction: Vector2 = offset / distance if distance > 0.0 else _get_random_direction()

		if distance < inner_radius:
			# NOTE: 双方が同じ処理を行うため、重なりを半分ずつ分担して離れる。
			_position_correction += direction * (inner_radius - distance) * 0.5

		var closeness := clampf(1.0 - distance / _outer_radius, 0.0, 1.0)
		_push_velocity += direction * max_push_speed * closeness


func get_push_velocity() -> Vector2:
	return _push_velocity


func get_position_correction() -> Vector2:
	return _position_correction


## 完全に重なった場合の押し出し方向を決める。
func _get_random_direction() -> Vector2:
	return Vector2.from_angle(randf_range(0.0, TAU))


func _get_outer_radius() -> float:
	var circle := _shape.shape as CircleShape2D
	if circle == null:
		push_error("Separation の CollisionShape2D には CircleShape2D を設定してください。")
		return inner_radius

	return circle.radius
