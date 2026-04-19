extends Resource
class_name GCEntityDefinition

const GCEntityComponent = preload("res://addons/game_core/entities/gc_entity_component.gd")
const GCEntityRuntime = preload("res://addons/game_core/entities/gc_entity_runtime.gd")
const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")

@export var id: StringName
@export var tags: PackedStringArray = []
@export var components: Array[GCEntityComponent] = []


func spawn(game_context: GCGameContext, overrides: Dictionary = {}) -> GCEntityRuntime:
	var runtime := GCEntityRuntime.new()
	return runtime.initialize(self, game_context, overrides)
