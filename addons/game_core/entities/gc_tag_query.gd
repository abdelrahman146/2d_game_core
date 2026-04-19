extends Resource
class_name GCTagQuery

@export var all_tags: PackedStringArray = []
@export var any_tags: PackedStringArray = []
@export var excluded_tags: PackedStringArray = []


func matches_entity(entity: Object) -> bool:
	if entity == null:
		return false
	var entity_tags: Variant = entity.get("tags")
	if entity_tags is PackedStringArray:
		return matches_tags(entity_tags as PackedStringArray)
	return false


func matches_tags(tags: PackedStringArray) -> bool:
	if not _contains_all(tags, all_tags):
		return false
	if not any_tags.is_empty() and not _contains_any(tags, any_tags):
		return false
	for tag in excluded_tags:
		if tags.has(tag):
			return false
	return true


func _contains_all(tags: PackedStringArray, required_tags: PackedStringArray) -> bool:
	for tag in required_tags:
		if not tags.has(tag):
			return false
	return true


func _contains_any(tags: PackedStringArray, candidate_tags: PackedStringArray) -> bool:
	for tag in candidate_tags:
		if tags.has(tag):
			return true
	return false