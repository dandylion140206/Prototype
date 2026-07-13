@abstract
class_name ActiveAbility
extends Node

@warning_ignore("unused_signal")
signal activated


@abstract
func setup(context: AbilityContext) -> void


@abstract
func try_activate() -> bool


@abstract
func deactivate() -> void
