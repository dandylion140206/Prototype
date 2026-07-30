@abstract
class_name CoinApproachTargetProvider
extends Node2D


@abstract
func setup(raid_area: CoinRaidArea, active_enemies: Node) -> void


@abstract
func assign_target(enemy: Enemy) -> Vector2


@abstract
func get_target_ratio(enemy: Enemy) -> float


@abstract
func release_target(enemy: Enemy) -> void


@abstract
func get_assignment_count() -> int
