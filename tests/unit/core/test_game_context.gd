extends "res://addons/gut/test.gd"


func test_context_serialize_round_trip_restores_runtime_shared_and_metadata() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	context.set_value(&"difficulty", &"hard")
	context.set_shared_value(&"seed", 42)
	context.metadata = {&"build": {&"version": 1}}

	var serialized := context.serialize()
	var restored: GCGameContext = autofree(GCGameContext.from_serialized_data(serialized))

	assert_eq(restored.get_value(&"difficulty"), &"hard")
	assert_eq(restored.get_shared_value(&"seed"), 42)
	assert_eq(restored.metadata[&"build"][&"version"], 1)
	assert_eq(restored.services.list_services(), [])


func test_context_apply_serialized_data_handles_missing_and_extra_fields() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	context.apply_serialized_data({
		&"runtime_state": {&"difficulty": &"normal"},
		&"extra": true,
	})

	assert_eq(context.get_value(&"difficulty"), &"normal")
	assert_eq(context.shared_state, {})
	assert_eq(context.metadata, {})