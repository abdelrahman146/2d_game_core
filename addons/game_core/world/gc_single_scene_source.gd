extends "res://addons/game_core/world/gc_world_source.gd"
class_name GCSingleSceneSource
## Loads a single scene as the world. For board games, card games, single-screen games.

@export var scene: PackedScene


func open(_context: GCGameContext, controller: GCWorldController, _payload: Dictionary = {}) -> void:
	if scene == null:
		push_warning("GCSingleSceneSource: No scene assigned.")
		return
	var instance := scene.instantiate()
	controller.set_world_root(instance)


func close(_context: GCGameContext, _controller: GCWorldController) -> void:
	pass
