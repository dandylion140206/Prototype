@abstract
class_name Ability
extends Node

@warning_ignore("unused_signal")
signal activated
@warning_ignore("unused_signal")
signal audio_requested(request: AudioRequest)


@abstract
func setup(context: AbilityContext) -> void


@abstract
func try_activate() -> bool


@abstract
func teardown() -> void
