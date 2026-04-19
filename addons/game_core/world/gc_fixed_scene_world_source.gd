extends "res://addons/game_core/world/gc_world_source.gd"
class_name GCFixedSceneWorldSource

@export var scene: PackedScene


func open_world(_context: GCGameContext, controller: GCWorldController, _payload: Dictionary = {}) -> void:
	if scene == null:
		push_warning("GCFixedSceneWorldSource has no scene configured.")
		return
	var world_instance := scene.instantiate()
	if world_instance is Node:
		controller.set_world_root(world_instance as Node)
		return
	push_warning("GCFixedSceneWorldSource scene must instantiate a Node.")


func close_world(_context: GCGameContext, _controller: GCWorldController) -> void:
	pass


func populate(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	pass