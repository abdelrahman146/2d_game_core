extends "res://addons/gut/test.gd"


class TrackingComponent extends "res://addons/game_core/entities/gc_entity_component.gd":
	var component_name := ""
	var initial_state: Dictionary = {}
	var event_log: Array = []

	func _init(next_name: String, next_state: Dictionary, next_event_log: Array) -> void:
		component_name = next_name
		initial_state = next_state
		event_log = next_event_log

	func build_state() -> Dictionary:
		return initial_state.duplicate(true)

	func create_runtime_component():
		return TrackingComponent.new(component_name, initial_state.duplicate(true), event_log)

	func on_entity_created(_entity, _context) -> void:
		event_log.append("created:%s" % component_name)

	func on_entity_destroyed(_entity, _context) -> void:
		event_log.append("destroyed:%s" % component_name)


class IsolatedComponent extends "res://addons/game_core/entities/gc_entity_component.gd":
	var initial_state: Dictionary = {}

	func _init(next_state: Dictionary) -> void:
		initial_state = next_state

	func build_state() -> Dictionary:
		return initial_state

	func create_runtime_component():
		return IsolatedComponent.new(initial_state.duplicate(true))


func test_spawn_builds_runtime_from_definition_and_components() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())

	definition.id = &"slime"
	definition.tags = PackedStringArray(["enemy", "slime"])
	definition.components = [
		TrackingComponent.new("health", {&"health": 5, &"max_health": 5}, event_log),
		TrackingComponent.new("flags", {&"is_alive": true}, event_log),
	]

	var runtime = autofree(definition.spawn(context, {
		&"entity_id": &"elite_slime",
		&"state": {&"health": 99},
	}))

	assert_eq(runtime.entity_id, &"elite_slime")
	assert_same(runtime.definition, definition)
	assert_same(runtime.context, context)
	assert_true(runtime.has_tag(&"enemy"))
	assert_true(runtime.has_tag(&"slime"))
	assert_eq(runtime.components.size(), 2)
	assert_eq(runtime.get_value(&"health"), 99)
	assert_eq(runtime.get_value(&"max_health"), 5)
	assert_true(runtime.get_value(&"is_alive", false))
	assert_eq(event_log, ["created:health", "created:flags"])


func test_destroy_calls_components_in_reverse_order() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())

	definition.id = &"slime"
	definition.components = [
		TrackingComponent.new("first", {}, event_log),
		TrackingComponent.new("second", {}, event_log),
	]

	var runtime = autofree(definition.spawn(context))
	runtime.destroy()

	assert_eq(
		event_log,
		["created:first", "created:second", "destroyed:second", "destroyed:first"]
	)


func test_spawn_creates_isolated_component_instances_and_state_copies() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())
	var component := IsolatedComponent.new({&"stats": {&"health": 5}})

	definition.id = &"slime"
	definition.components = [component]

	var first_runtime = autofree(definition.spawn(context))
	var second_runtime = autofree(definition.spawn(context))

	assert_ne(first_runtime.components[0], component)
	assert_ne(second_runtime.components[0], component)
	assert_ne(first_runtime.components[0], second_runtime.components[0])

	var first_state: Dictionary = first_runtime.get_value(&"stats")
	first_state[&"health"] = 1

	assert_eq(component.initial_state[&"stats"][&"health"], 5)
	assert_eq(second_runtime.get_value(&"stats")[&"health"], 5)


func test_spawn_from_serialized_data_restores_state_and_tags() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())

	definition.id = &"slime"
	definition.tags = PackedStringArray(["enemy", "slime"])
	definition.components = [TrackingComponent.new("health", {&"health": 5}, [])]

	var runtime = autofree(definition.spawn_from_serialized_data(context, {
		&"version": 1,
		&"definition_id": &"slime",
		&"entity_id": &"boss_slime",
		&"tags": PackedStringArray(["enemy", "boss"]),
		&"state": {&"health": 20, &"phase": 2},
	}))

	assert_true(runtime != null)
	assert_eq(runtime.entity_id, &"boss_slime")
	assert_true(runtime.has_tag(&"boss"))
	assert_false(runtime.has_tag(&"slime"))
	assert_eq(runtime.get_value(&"health"), 20)
	assert_eq(runtime.get_value(&"phase"), 2)


func test_entity_serialize_round_trip_keeps_missing_fields_safe() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var definition: GCEntityDefinition = autofree(GCEntityDefinition.new())

	definition.id = &"slime"
	definition.tags = PackedStringArray(["enemy"])
	var runtime = autofree(definition.spawn(context, {
		&"entity_id": &"elite",
		&"state": {&"nested": {&"health": 8}},
	}))
	var serialized: Dictionary = runtime.serialize()
	serialized[&"state"][&"nested"][&"health"] = 2
	serialized.erase(&"tags")
	serialized[&"extra"] = true

	runtime.apply_serialized_data(serialized)

	assert_eq(runtime.entity_id, &"elite")
	assert_true(runtime.has_tag(&"enemy"))
	assert_eq(runtime.get_value(&"nested")[&"health"], 2)
