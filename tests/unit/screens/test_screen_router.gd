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


func _make_invalid_definition(screen_id: StringName) -> GCScreenDefinition:
	var packed_scene: PackedScene = autofree(PackedScene.new())
	var plain_node := Node.new()
	assert_eq(packed_scene.pack(plain_node), OK)
	plain_node.free()
	assert_freed(plain_node, "invalid packed screen source")
	var definition: GCScreenDefinition = autofree(GCScreenDefinition.new())
	definition.id = screen_id
	definition.scene = packed_scene
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


func test_push_and_pop_reuse_persistent_screen_history() -> void:
	var router: GCScreenRouter = add_child_autoqfree(GCScreenRouter.new())
	router.definitions = [
		_make_definition(&"gameplay", true),
		_make_definition(&"pause", false),
	]
	router.configure(autofree(GCGameContext.new()))

	router.go_to(&"gameplay", {&"source": &"boot"})
	var gameplay_screen: Node = router.current_screen
	router.push(&"pause", {&"source": &"pause"})
	var pause_screen: Node = router.current_screen

	assert_true(router.can_pop())
	assert_eq(pause_screen.get("enter_count"), 1)
	assert_eq(gameplay_screen.get("exit_count"), 1)

	router.pop({&"source": &"resume"})
	await wait_physics_frames(1, "allow queued frees to complete")
	var resumed_gameplay: Node = router.current_screen

	assert_same(gameplay_screen, resumed_gameplay)
	assert_eq(resumed_gameplay.get("enter_count"), 2)
	assert_eq(resumed_gameplay.get("last_payload"), {&"source": &"resume"})
	assert_freed(pause_screen, "pause screen should be freed after pop")
	assert_false(router.can_pop())
	assert_no_new_orphans()


func test_duplicate_definitions_keep_the_first_registered_screen() -> void:
	var router: GCScreenRouter = add_child_autoqfree(GCScreenRouter.new())
	var first_definition := _make_definition(&"menu")
	var second_definition := _make_definition(&"menu")
	router.definitions = [first_definition, second_definition]
	router.configure(autofree(GCGameContext.new()))

	assert_same(router.get_definition(&"menu"), first_definition)
	assert_true(router.has_definition(&"menu"))

	router.go_to(&"menu")

	assert_same(router.current_screen.screen_definition, first_definition)
	assert_no_new_orphans()


func test_invalid_scene_definition_is_skipped_without_activating_a_screen() -> void:
	var router: GCScreenRouter = add_child_autoqfree(GCScreenRouter.new())
	router.definitions = [_make_invalid_definition(&"invalid")]
	router.configure(autofree(GCGameContext.new()))

	assert_true(router.has_definition(&"invalid"))

	router.go_to(&"invalid")
	await wait_physics_frames(1, "allow invalid screen cleanup to complete")

	assert_eq(router.current_screen, null)
	assert_eq(router.current_screen_id, StringName())
	assert_no_new_orphans()
