extends Resource
class_name GCWorldSource
## Base contract for world loading strategies.
## Extend this for level-based, room-based, procedural, or single-scene worlds.


func open(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	pass


func close(_context: GCGameContext, _controller: GCWorldController) -> void:
	pass


func populate(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	pass
