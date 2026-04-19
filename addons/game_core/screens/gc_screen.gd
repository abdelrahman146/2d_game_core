extends Node
class_name GCScreen
## Base class for screens managed by the router.
## Extend this and implement enter/exit hooks.

var context: GCGameContext


func setup(game_context: GCGameContext) -> void:
	context = game_context


func enter(_payload: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func pause() -> void:
	pass


func resume() -> void:
	pass
