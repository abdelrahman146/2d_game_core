extends "res://addons/gut/test.gd"

const GCTagQueryScript = preload("res://addons/game_core/entities/gc_tag_query.gd")


func _make_runtime(tags: PackedStringArray):
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())
	definition.id = &"entity"
	definition.tags = tags
	return autofree(definition.spawn(autofree(GCGameContext.new())))


func test_tag_query_matches_all_any_and_excluded_tags() -> void:
	var query = autofree(GCTagQueryScript.new())
	query.all_tags = PackedStringArray(["enemy"])
	query.any_tags = PackedStringArray(["flying", "armored"])
	query.excluded_tags = PackedStringArray(["dead"])

	assert_true(query.matches_entity(_make_runtime(PackedStringArray(["enemy", "flying"]))))
	assert_false(query.matches_entity(_make_runtime(PackedStringArray(["enemy", "dead", "flying"]))))
	assert_false(query.matches_entity(_make_runtime(PackedStringArray(["enemy", "ground"]))))


func test_entity_runtime_exposes_query_helpers() -> void:
	var runtime = _make_runtime(PackedStringArray(["enemy", "boss", "flying"]))
	var query = autofree(GCTagQueryScript.new())
	query.all_tags = PackedStringArray(["enemy", "boss"])

	assert_true(runtime.has_all_tags(PackedStringArray(["enemy", "boss"])))
	assert_true(runtime.has_any_tags(PackedStringArray(["player", "flying"])))
	assert_true(runtime.has_none_tags(PackedStringArray(["dead", "neutral"])))
	assert_true(runtime.matches_tag_query(query))