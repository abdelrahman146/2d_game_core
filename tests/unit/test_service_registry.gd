extends GutTest
## Tests for GCServiceRegistry: registration, ordering, lifecycle.


class TrackingService extends GCService:
	var start_order := -1
	var stop_order := -1
	static var _counter := 0

	func start(ctx: GCGameContext) -> void:
		super.start(ctx)
		start_order = TrackingService._counter
		TrackingService._counter += 1

	func stop() -> void:
		super.stop()
		stop_order = TrackingService._counter
		TrackingService._counter += 1

	static func reset_counter() -> void:
		_counter = 0


func before_each() -> void:
	TrackingService.reset_counter()


func _create_registry() -> GCServiceRegistry:
	return autofree(GCServiceRegistry.new())


func _create_context() -> GCGameContext:
	return autofree(GCGameContext.new())


func test_register_and_get_service() -> void:
	var reg := _create_registry()
	var svc: GCService = autofree(GCService.new())
	reg.register(&"audio", svc)
	assert_eq(reg.get_service(&"audio"), svc)


func test_has_service_true_when_registered() -> void:
	var reg := _create_registry()
	reg.register(&"save", autofree(GCService.new()))
	assert_true(reg.has_service(&"save"))


func test_has_service_false_when_not_registered() -> void:
	var reg := _create_registry()
	assert_false(reg.has_service(&"unknown"))


func test_get_all_ids_returns_registered_order() -> void:
	var reg := _create_registry()
	reg.register(&"first", autofree(GCService.new()))
	reg.register(&"second", autofree(GCService.new()))
	reg.register(&"third", autofree(GCService.new()))
	var ids := reg.get_all_ids()
	assert_eq(ids[0], "first")
	assert_eq(ids[1], "second")
	assert_eq(ids[2], "third")


func test_start_all_starts_services_in_order() -> void:
	var reg := _create_registry()
	var ctx := _create_context()
	var a: TrackingService = autofree(TrackingService.new())
	var b: TrackingService = autofree(TrackingService.new())
	var c: TrackingService = autofree(TrackingService.new())
	reg.register(&"a", a)
	reg.register(&"b", b)
	reg.register(&"c", c)
	reg.start_all(ctx)
	assert_eq(a.start_order, 0)
	assert_eq(b.start_order, 1)
	assert_eq(c.start_order, 2)
	assert_true(a.is_running)
	assert_true(b.is_running)
	assert_true(c.is_running)


func test_stop_all_stops_services_in_reverse_order() -> void:
	var reg := _create_registry()
	var ctx := _create_context()
	var a: TrackingService = autofree(TrackingService.new())
	var b: TrackingService = autofree(TrackingService.new())
	var c: TrackingService = autofree(TrackingService.new())
	reg.register(&"a", a)
	reg.register(&"b", b)
	reg.register(&"c", c)
	reg.start_all(ctx)
	TrackingService.reset_counter()
	reg.stop_all()
	# c stopped first (order 0), then b (order 1), then a (order 2)
	assert_eq(c.stop_order, 0)
	assert_eq(b.stop_order, 1)
	assert_eq(a.stop_order, 2)
	assert_false(a.is_running)
	assert_false(b.is_running)
	assert_false(c.is_running)


func test_replace_service_stops_old_and_uses_new() -> void:
	var reg := _create_registry()
	var ctx := _create_context()
	var old_svc: TrackingService = autofree(TrackingService.new())
	var new_svc: TrackingService = autofree(TrackingService.new())
	reg.register(&"svc", old_svc)
	reg.start_all(ctx)
	assert_true(old_svc.is_running)
	reg.register(&"svc", new_svc)
	assert_false(old_svc.is_running)
	assert_true(new_svc.is_running)
	assert_eq(reg.get_service(&"svc"), new_svc)


func test_late_registration_starts_immediately_if_running() -> void:
	var reg := _create_registry()
	var ctx := _create_context()
	reg.start_all(ctx)
	var late: TrackingService = autofree(TrackingService.new())
	reg.register(&"late", late)
	assert_true(late.is_running)


func test_get_service_returns_null_for_unknown() -> void:
	var reg := _create_registry()
	assert_null(reg.get_service(&"nope"))
