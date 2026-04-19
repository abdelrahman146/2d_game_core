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


func spawn_from_serialized_data(game_context: GCGameContext, data: Dictionary) -> GCEntityRuntime:
	var serialized_definition_id := StringName(data.get(&"definition_id", id))
	if not serialized_definition_id.is_empty() and serialized_definition_id != id:
		push_warning(
			"Serialized entity data references definition '%s', expected '%s'." % [serialized_definition_id, id]
		)
		return null
	var runtime := spawn(game_context, {
		&"entity_id": data.get(&"entity_id", id),
		&"tags": data.get(&"tags", tags),
		&"state": data.get(&"state", {}),
	})
	runtime.apply_serialized_data(data)
	return runtime
