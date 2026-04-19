extends Resource
class_name GCEntityComponent

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")

@export var id: StringName


func create_runtime_component() -> GCEntityComponent:
	var runtime_component := duplicate(true) as GCEntityComponent
	if runtime_component == null:
		return self
	return runtime_component


func on_entity_created(_entity, _context: GCGameContext) -> void:
	pass


func on_entity_destroyed(_entity, _context: GCGameContext) -> void:
	pass


func build_state() -> Dictionary:
	return {}
