extends Resource
class_name GCWorldSource

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCWorldController = preload("res://addons/game_core/world/gc_world_controller.gd")


func open_world(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	pass


func close_world(_context: GCGameContext, _controller: GCWorldController) -> void:
	pass


func populate(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	pass
