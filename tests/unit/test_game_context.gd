extends GutTest
## Tests for GCGameContext: state, signals, serialization.


func _create_context() -> GCGameContext:
	var ctx := GCGameContext.new()
	return autofree(ctx) as GCGameContext


func test_set_and_get_value() -> void:
	var ctx := _create_context()
	ctx.set_value(&"score", 42)
	assert_eq(ctx.get_value(&"score"), 42)


func test_get_value_returns_default_when_missing() -> void:
	var ctx := _create_context()
	assert_eq(ctx.get_value(&"missing", -1), -1)


func test_has_value_true_when_set() -> void:
	var ctx := _create_context()
	ctx.set_value(&"lives", 3)
	assert_true(ctx.has_value(&"lives"))


func test_has_value_false_when_not_set() -> void:
	var ctx := _create_context()
	assert_false(ctx.has_value(&"anything"))


func test_clear_value_removes_key() -> void:
	var ctx := _create_context()
	ctx.set_value(&"health", 10)
	ctx.clear_value(&"health")
	assert_false(ctx.has_value(&"health"))


func test_state_changed_signal_emits_key_and_value() -> void:
	var ctx := _create_context()
	watch_signals(ctx)
	ctx.set_value(&"level", 5)
	assert_signal_emitted_with_parameters(ctx, "state_changed", [&"level", 5])


func test_player_data_set_and_get() -> void:
	var ctx := _create_context()
	ctx.set_player_value(&"name", "Hero")
	assert_eq(ctx.get_player_value(&"name"), "Hero")


func test_player_data_changed_signal() -> void:
	var ctx := _create_context()
	watch_signals(ctx)
	ctx.set_player_value(&"coins", 100)
	assert_signal_emitted_with_parameters(ctx, "player_data_changed", [&"coins", 100])


func test_clear_resets_all_dictionaries() -> void:
	var ctx := _create_context()
	ctx.set_value(&"a", 1)
	ctx.set_player_value(&"b", 2)
	ctx.metadata[&"c"] = 3
	ctx.clear()
	assert_eq(ctx.state.size(), 0)
	assert_eq(ctx.player_data.size(), 0)
	assert_eq(ctx.metadata.size(), 0)


func test_serialize_produces_deep_copy() -> void:
	var ctx := _create_context()
	ctx.set_value(&"x", 10)
	ctx.set_player_value(&"y", 20)
	ctx.metadata[&"z"] = 30
	var data := ctx.serialize()
	assert_eq(data[&"state"][&"x"], 10)
	assert_eq(data[&"player_data"][&"y"], 20)
	assert_eq(data[&"metadata"][&"z"], 30)
	# Mutating serialized data does not affect original
	data[&"state"][&"x"] = 999
	assert_eq(ctx.get_value(&"x"), 10)


func test_deserialize_restores_state() -> void:
	var ctx := _create_context()
	var data := {
		&"state": {&"level": 7},
		&"player_data": {&"name": "Test"},
		&"metadata": {&"version": 1},
	}
	ctx.deserialize(data)
	assert_eq(ctx.get_value(&"level"), 7)
	assert_eq(ctx.get_player_value(&"name"), "Test")
	assert_eq(ctx.metadata[&"version"], 1)


func test_deserialize_is_isolated_from_source_dict() -> void:
	var ctx := _create_context()
	var data := {&"state": {&"hp": 5}, &"player_data": {}, &"metadata": {}}
	ctx.deserialize(data)
	data[&"state"][&"hp"] = 999
	assert_eq(ctx.get_value(&"hp"), 5)
