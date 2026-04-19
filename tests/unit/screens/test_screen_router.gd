extends "res://addons/gut/test.gd"

const SCREEN_HELPER_SCRIPT = preload("res://tests/helpers/screen_helper.gd")


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


func test_go_to_instantiates_and_enters_requested_screen() -> void:
	var router: GCScreenRouter = add_child_autoqfree(GCScreenRouter.new())
	router.definitions = [_make_definition(&"menu")]
	router.configure(autofree(GCGameContext.new()))

	router.go_to(&"menu", {&"source": &"boot"})

	var current_screen: Node = router.current_screen
	assert_true(current_screen != null)
	assert_eq(router.current_screen_id, &"menu")
	assert_same(current_screen.screen_definition, router.definitions[0])
	assert_same(current_screen.get_parent(), router)
	assert_eq(current_screen.get("enter_count"), 1)
	assert_eq(current_screen.get("exit_count"), 0)
	assert_eq(current_screen.get("last_payload"), {&"source": &"boot"})
	assert_no_new_orphans()


func test_persistent_screens_are_reused_and_non_persistent_screens_are_freed() -> void:
	var router: GCScreenRouter = add_child_autoqfree(GCScreenRouter.new())
	router.definitions = [
		_make_definition(&"menu", true),
		_make_definition(&"gameplay", false),
	]
	router.configure(autofree(GCGameContext.new()))

	router.go_to(&"menu")
	var first_menu: Node = router.current_screen
	router.go_to(&"gameplay")
	var gameplay_screen: Node = router.current_screen
	assert_eq(first_menu.get("exit_count"), 1)
	assert_eq(router.current_screen_id, &"gameplay")
	assert_not_freed(first_menu, "persistent menu screen")
	assert_true(first_menu.get_parent() == null)
	router.go_to(&"menu")
	assert_eq(gameplay_screen.get("exit_count"), 1)
	assert_true(gameplay_screen.get_parent() == null)
	await wait_physics_frames(1, "allow queued frees to complete")
	var second_menu: Node = router.current_screen

	assert_same(first_menu, second_menu)
	assert_eq(second_menu.get("enter_count"), 2)
	assert_freed(gameplay_screen, "non-persistent gameplay screen")
	assert_no_new_orphans()
