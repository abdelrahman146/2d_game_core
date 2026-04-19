extends "res://addons/gut/test.gd"

const SCREEN_HELPER_SCRIPT = preload("res://tests/helpers/screen_helper.gd")


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


func _make_scene() -> PackedScene:
	var packed_scene: PackedScene = autofree(PackedScene.new())
	var screen: Node = SCREEN_HELPER_SCRIPT.new()
	var pack_result: int = packed_scene.pack(screen)
	assert_eq(pack_result, OK)
	screen.free()
	assert_freed(screen, "packed screen source")
	return packed_scene


func _make_definition(screen_id: StringName, is_persistent := false) -> GCScreenDefinition:
	var definition: GCScreenDefinition = autofree(GCScreenDefinition.new())
	definition.id = screen_id
	definition.is_persistent = is_persistent
	definition.scene = _make_scene()
	return definition


func test_prebootstrap_registered_service_survives_bootstrap() -> void:
	var core := GCGameCore.new()
	core.auto_bootstrap = false
	add_child_autoqfree(core)
	var event_log: Array = []
	var service := TrackingService.new(&"manual", event_log)

	core.register_service(&"manual", service)
	core.bootstrap()

	assert_same(core.context.services.get_service(&"manual"), service)
	assert_true(core.context.get_value(&"manual", false))
	assert_eq(event_log, ["setup:manual"])
	assert_no_new_orphans()


func test_registering_service_after_bootstrap_sets_it_up_immediately() -> void:
	var core := GCGameCore.new()
	core.auto_bootstrap = false
	add_child_autoqfree(core)
	var event_log: Array = []

	core.bootstrap()
	core.register_service(&"late", TrackingService.new(&"late", event_log))

	assert_eq(event_log, ["setup:late"])
	assert_true(core.context.get_value(&"late", false))

	core.shutdown()

	assert_eq(event_log, ["setup:late", "teardown:late"])
	assert_eq(core.context, null)
	assert_no_new_orphans()


func test_shutdown_clears_router_state_and_recreates_persistent_screens_on_rebootstrap() -> void:
	var core := GCGameCore.new()
	core.auto_bootstrap = false
	core.initial_screen = &"menu"
	add_child_autoqfree(core)
	var router := GCScreenRouter.new()
	router.definitions = [_make_definition(&"menu", true)]
	core.add_child(router)

	core.bootstrap()
	var first_screen: Node = router.current_screen

	assert_same(core.screen_router, router)
	assert_same(router.context, core.context)
	assert_eq(router.current_screen_id, &"menu")
	assert_true(first_screen != null)
	assert_eq(first_screen.get("enter_count"), 1)

	core.shutdown()

	assert_eq(router.current_screen, null)
	assert_eq(router.current_screen_id, StringName())
	assert_eq(router.context, null)
	await wait_physics_frames(1, "allow shutdown frees to complete")
	assert_freed(first_screen, "persistent screen should be cleared on shutdown")

	core.bootstrap()
	var second_screen: Node = router.current_screen

	assert_true(second_screen != null)
	assert_false(first_screen == second_screen)
	assert_eq(router.current_screen_id, &"menu")
	assert_same(router.context, core.context)
	assert_eq(second_screen.get("enter_count"), 1)
	assert_no_new_orphans()