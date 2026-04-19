extends RefCounted
class_name GCEntityRuntime

const GCEntityComponent = preload("res://addons/game_core/entities/gc_entity_component.gd")
const GCEntityDefinition = preload("res://addons/game_core/entities/gc_entity_definition.gd")
const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")

signal event_emitted(event_name: StringName, payload: Dictionary)

var entity_id: StringName
var definition: GCEntityDefinition
var context: GCGameContext
var tags: PackedStringArray = []
var state: Dictionary = {}
var components: Array[GCEntityComponent] = []


func initialize(entity_definition: GCEntityDefinition, game_context: GCGameContext, overrides: Dictionary = {}) -> GCEntityRuntime:
	definition = entity_definition
	context = game_context
	entity_id = overrides.get(&"entity_id", definition.id)
	tags = definition.tags.duplicate()
	components = definition.components.duplicate()
	state = overrides.get(&"state", {})
	for component in components:
		state.merge(component.build_state(), false)
		component.on_entity_created(self, context)
	return self


func destroy() -> void:
	for index in range(components.size() - 1, -1, -1):
		components[index].on_entity_destroyed(self, context)


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func set_value(key: StringName, value: Variant) -> void:
	state[key] = value


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return state.get(key, default_value)


func emit_event(event_name: StringName, payload: Dictionary = {}) -> void:
	event_emitted.emit(event_name, payload)
