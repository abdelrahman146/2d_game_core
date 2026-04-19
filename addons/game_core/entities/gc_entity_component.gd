extends Resource
class_name GCEntityComponent

const GCEntityRuntime = preload("res://addons/game_core/entities/gc_entity_runtime.gd")
const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")

@export var id: StringName


func on_entity_created(_entity: GCEntityRuntime, _context: GCGameContext) -> void:
	pass


func on_entity_destroyed(_entity: GCEntityRuntime, _context: GCGameContext) -> void:
	pass


func build_state() -> Dictionary:
	return {}
