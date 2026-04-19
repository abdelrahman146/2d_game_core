extends "res://addons/gut/test.gd"


class TrackingService extends "res://addons/game_core/core/gc_service.gd":
	var service_name: StringName
	var event_log: Array

	func _init(next_service_name: StringName, next_event_log: Array) -> void:
		service_name = next_service_name
		event_log = next_event_log

	func setup(context) -> void:
		event_log.append("setup:%s" % service_name)
		context.set_value(service_name, true)

	func teardown() -> void:
		event_log.append("teardown:%s" % service_name)


func test_services_setup_in_registration_order() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []
	var first := TrackingService.new(&"first", event_log)
	var second := TrackingService.new(&"second", event_log)

	context.services.register_service(&"first", first)
	context.services.register_service(&"second", second)
	assert_eq(context.services.list_services(), [&"first", &"second"])
	context.services.setup_all(context)

	assert_eq(event_log, ["setup:first", "setup:second"])
	assert_true(context.get_value(&"first", false))
	assert_true(context.get_value(&"second", false))


func test_services_teardown_in_reverse_order() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []

	context.services.register_service(&"first", TrackingService.new(&"first", event_log))
	context.services.register_service(&"second", TrackingService.new(&"second", event_log))
	context.services.setup_all(context)
	context.services.teardown_all()

	assert_eq(
		event_log,
		["setup:first", "setup:second", "teardown:second", "teardown:first"]
	)
	assert_eq(context.services.list_services(), [])


func test_registering_service_after_setup_sets_it_up_immediately() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []

	context.services.setup_all(context)
	context.services.register_service(&"late", TrackingService.new(&"late", event_log))

	assert_eq(event_log, ["setup:late"])
	assert_true(context.get_value(&"late", false))


func test_replacing_started_service_tears_down_old_service_and_sets_up_new_one() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []

	context.services.register_service(&"shared", TrackingService.new(&"first", event_log))
	context.services.setup_all(context)
	context.services.register_service(&"shared", TrackingService.new(&"second", event_log))

	assert_eq(event_log, ["setup:first", "teardown:first", "setup:second"])
	assert_eq(context.services.list_services(), [&"shared"])
	assert_same(context.services.get_service(&"shared").service_name, &"second")
	assert_true(context.get_value(&"second", false))


func test_unregister_only_tears_down_started_services() -> void:
	var context: GCGameContext = autofree(GCGameContext.new())
	var event_log: Array = []

	context.services.register_service(&"pending", TrackingService.new(&"pending", event_log))
	context.services.unregister_service(&"pending")
	assert_eq(event_log, [])

	context.services.register_service(&"started", TrackingService.new(&"started", event_log))
	context.services.setup_all(context)
	context.services.unregister_service(&"started")
	context.services.unregister_service(&"started")

	assert_eq(event_log, ["setup:started", "teardown:started"])
	assert_eq(context.services.list_services(), [])
