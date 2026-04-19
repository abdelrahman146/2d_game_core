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

	func on_entity_created(_entity, _context) -> void:
		event_log.append("created:%s" % component_name)

	func on_entity_destroyed(_entity, _context) -> void:
		event_log.append("destroyed:%s" % component_name)


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
