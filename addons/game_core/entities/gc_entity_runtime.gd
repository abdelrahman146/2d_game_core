extends RefCounted
class_name GCEntityRuntime

const GCEntityComponent = preload("res://addons/game_core/entities/gc_entity_component.gd")
const GCEntityDefinition = preload("res://addons/game_core/entities/gc_entity_definition.gd")
const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")

const SERIALIZATION_VERSION := 1

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
	tags = _resolve_tags(overrides.get(&"tags", definition.tags))
	components = _instantiate_components(definition.components)
	state = _deep_copy_dictionary(overrides.get(&"state", {}))
	for component in components:
		state.merge(_deep_copy_dictionary(component.build_state()), false)
		component.on_entity_created(self, context)
	return self


func destroy() -> void:
	for index in range(components.size() - 1, -1, -1):
		components[index].on_entity_destroyed(self, context)


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func has_all_tags(required_tags: PackedStringArray) -> bool:
	for tag in required_tags:
		if not has_tag(tag):
			return false
	return true


func has_any_tags(candidate_tags: PackedStringArray) -> bool:
	for tag in candidate_tags:
		if has_tag(tag):
			return true
	return false


func has_none_tags(forbidden_tags: PackedStringArray) -> bool:
	for tag in forbidden_tags:
		if has_tag(tag):
			return false
	return true


func matches_tag_query(query: Resource) -> bool:
	if query == null:
		return true
	if not query.has_method("matches_tags"):
		return false
	return bool(query.call("matches_tags", tags))


func set_value(key: StringName, value: Variant) -> void:
	state[key] = value


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return state.get(key, default_value)


func get_state_copy() -> Dictionary:
	return state.duplicate(true)


func serialize() -> Dictionary:
	return {
		&"version": SERIALIZATION_VERSION,
		&"definition_id": _get_definition_id(),
		&"entity_id": entity_id,
		&"tags": tags.duplicate(),
		&"state": get_state_copy(),
	}


func apply_serialized_data(data: Dictionary) -> void:
	entity_id = data.get(&"entity_id", entity_id)
	tags = _resolve_tags(data.get(&"tags", tags))
	state = _deep_copy_dictionary(data.get(&"state", state))


func emit_event(event_name: StringName, payload: Dictionary = {}) -> void:
	event_emitted.emit(event_name, payload)


func _instantiate_components(definition_components: Array[GCEntityComponent]) -> Array[GCEntityComponent]:
	var runtime_components: Array[GCEntityComponent] = []
	for component in definition_components:
		if component == null:
			continue
		runtime_components.append(component.create_runtime_component())
	return runtime_components


func _resolve_tags(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()
	if value is Array:
		return PackedStringArray(value as Array)
	return PackedStringArray()


func _deep_copy_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _get_definition_id() -> StringName:
	if definition == null:
		return StringName()
	return definition.id
