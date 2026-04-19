extends Resource
class_name GCInteraction

const GCEntityRuntime = preload("res://addons/game_core/entities/gc_entity_runtime.gd")
const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCTagQuery = preload("res://addons/game_core/entities/gc_tag_query.gd")

@export var id: StringName
@export var required_source_tags: PackedStringArray = []
@export var required_target_tags: PackedStringArray = []
@export var source_tag_query: Resource
@export var target_tag_query: Resource


func can_apply(source: GCEntityRuntime, target: GCEntityRuntime, _payload: Dictionary = {}) -> bool:
	return (
		_matches_tags(source, required_source_tags)
		and _matches_tags(target, required_target_tags)
		and _matches_query(source, source_tag_query as GCTagQuery)
		and _matches_query(target, target_tag_query as GCTagQuery)
	)


func apply(_source: GCEntityRuntime, _target: GCEntityRuntime, _context: GCGameContext, _payload: Dictionary = {}) -> void:
	pass


func _matches_tags(entity: GCEntityRuntime, required_tags: PackedStringArray) -> bool:
	if required_tags.is_empty():
		return true
	if entity == null:
		return false
	for tag in required_tags:
		if not entity.has_tag(tag):
			return false
	return true


func _matches_query(entity: GCEntityRuntime, query: GCTagQuery) -> bool:
	if query == null:
		return true
	if entity == null:
		return false
	return entity.matches_tag_query(query)
