extends "res://addons/gut/test.gd"

const GCTagQueryScript = preload("res://addons/game_core/entities/gc_tag_query.gd")


func _make_runtime(tags: PackedStringArray):
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())
	definition.id = &"entity"
	definition.tags = tags
	return autofree(definition.spawn(autofree(GCGameContext.new())))


func test_can_apply_returns_true_when_source_and_target_match_required_tags() -> void:
	var interaction: GCInteraction = autofree(GCInteraction.new())
	interaction.required_source_tags = PackedStringArray(["player"])
	interaction.required_target_tags = PackedStringArray(["enemy"])

	assert_true(
		interaction.can_apply(
			_make_runtime(PackedStringArray(["player", "alive"])),
			_make_runtime(PackedStringArray(["enemy"])),
			{}
		)
	)


func test_can_apply_returns_false_when_source_tags_do_not_match() -> void:
	var interaction: GCInteraction = autofree(GCInteraction.new())
	interaction.required_source_tags = PackedStringArray(["player"])
	interaction.required_target_tags = PackedStringArray(["enemy"])

	assert_false(
		interaction.can_apply(
			_make_runtime(PackedStringArray(["npc"])),
			_make_runtime(PackedStringArray(["enemy"])),
			{}
		)
	)


func test_can_apply_returns_false_when_target_tags_do_not_match() -> void:
	var interaction: GCInteraction = autofree(GCInteraction.new())
	interaction.required_source_tags = PackedStringArray(["player"])
	interaction.required_target_tags = PackedStringArray(["enemy"])

	assert_false(
		interaction.can_apply(
			_make_runtime(PackedStringArray(["player"])),
			_make_runtime(PackedStringArray(["neutral"])),
			{}
		)
	)


func test_can_apply_supports_richer_tag_queries() -> void:
	var interaction: GCInteraction = autofree(GCInteraction.new())
	var source_query = autofree(GCTagQueryScript.new())
	var target_query = autofree(GCTagQueryScript.new())
	source_query.any_tags = PackedStringArray(["ranged", "magic"])
	target_query.excluded_tags = PackedStringArray(["shielded"])
	interaction.source_tag_query = source_query
	interaction.target_tag_query = target_query

	assert_true(
		interaction.can_apply(
			_make_runtime(PackedStringArray(["player", "magic"])),
			_make_runtime(PackedStringArray(["enemy"])),
			{}
		)
	)
	assert_false(
		interaction.can_apply(
			_make_runtime(PackedStringArray(["player"])),
			_make_runtime(PackedStringArray(["enemy"])),
			{}
		)
	)
	assert_false(
		interaction.can_apply(
			_make_runtime(PackedStringArray(["player", "magic"])),
			_make_runtime(PackedStringArray(["enemy", "shielded"])),
			{}
		)
	)
