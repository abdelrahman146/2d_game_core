extends "res://addons/game_core/world/gc_world_source.gd"
class_name GCLevelSource
## Loads levels by id from a list of scenes. For level-based games.

const _LevelData = preload("res://addons/game_core/resources/gc_level_data.gd")

@export var levels: Array[_LevelData] = []

var _current_index := -1


func open(context: GCGameContext, controller: GCWorldController, payload: Dictionary = {}) -> void:
	var level_id: Variant = payload.get(&"level_id", null)
	var level: _LevelData = _find_level(level_id)
	if level == null:
		push_warning("GCLevelSource: Level '%s' not found." % str(level_id))
		return
	if level.scene == null:
		push_warning("GCLevelSource: Level '%s' has no scene." % str(level_id))
		return
	var instance: Node = level.scene.instantiate()
	controller.set_world_root(instance)


func close(_context: GCGameContext, _controller: GCWorldController) -> void:
	pass


func get_level_count() -> int:
	return levels.size()


func get_level_at(index: int) -> _LevelData:
	if index < 0 or index >= levels.size():
		return null
	return levels[index]


func get_next_level_id() -> Variant:
	if _current_index + 1 < levels.size():
		return levels[_current_index + 1].level_id
	return null


func _find_level(level_id: Variant) -> _LevelData:
	for i in range(levels.size()):
		if levels[i].level_id == level_id:
			_current_index = i
			return levels[i]
	return null
