extends "res://addons/gut/test.gd"


func _make_scene(node_name: String) -> PackedScene:
	var scene: PackedScene = autofree(PackedScene.new())
	var node := Node.new()
	node.name = node_name
	assert_eq(scene.pack(node), OK)
	node.free()
	assert_freed(node, "packed node source")
	return scene


func test_fixed_scene_world_source_sets_and_clears_world_root() -> void:
	var controller: GCWorldController = add_child_autoqfree(GCWorldController.new())
	var source: GCFixedSceneWorldSource = autofree(GCFixedSceneWorldSource.new())
	source.scene = _make_scene("LevelRoot")
	controller.source = source
	controller.configure(autofree(GCGameContext.new()))

	controller.open_world({&"level": &"intro"})
	var world_root: Node = controller.get_world_root()

	assert_true(controller.is_open)
	assert_true(world_root != null)
	assert_eq(world_root.name, "LevelRoot")
	assert_same(world_root.get_parent(), controller)

	controller.close_world()
	await wait_physics_frames(1, "allow world root free to complete")

	assert_false(controller.is_open)
	assert_eq(controller.get_world_root(), null)
	assert_freed(world_root, "fixed scene world root")
	assert_no_new_orphans()


func test_chunk_sequence_world_source_populates_and_trims_chunks() -> void:
	var controller: GCWorldController = add_child_autoqfree(GCWorldController.new())
	var source: GCChunkSequenceWorldSource = autofree(GCChunkSequenceWorldSource.new())
	source.chunk_scenes = [
		_make_scene("ChunkA"),
		_make_scene("ChunkB"),
	]
	controller.source = source
	controller.configure(autofree(GCGameContext.new()))

	controller.open_world()
	var world_root: Node = controller.get_world_root()
	var initial_chunks := source.get_loaded_chunks(controller)

	assert_true(world_root != null)
	assert_eq(world_root.name, "world_chunks")
	assert_eq(initial_chunks.size(), 2)
	assert_eq(initial_chunks[0].name, "ChunkA")
	assert_eq(initial_chunks[1].name, "ChunkB")

	var appended_chunk: Node = source.append_chunk(controller, _make_scene("ChunkC"))
	var chunks_after_append := source.get_loaded_chunks(controller)
	assert_true(appended_chunk != null)
	assert_eq(chunks_after_append.size(), 3)
	assert_eq(chunks_after_append[2].name, "ChunkC")

	var first_chunk: Node = chunks_after_append[0]
	source.trim_chunks(controller, 2, true)
	await wait_physics_frames(1, "allow trimmed chunks to free")
	var remaining_chunks := source.get_loaded_chunks(controller)

	assert_eq(remaining_chunks.size(), 2)
	assert_eq(remaining_chunks[0].name, "ChunkB")
	assert_eq(remaining_chunks[1].name, "ChunkC")
	assert_freed(first_chunk, "trimmed front chunk")

	controller.close_world()
	await wait_physics_frames(1, "allow chunk world root free to complete")

	assert_false(controller.is_open)
	assert_eq(controller.get_world_root(), null)
	assert_freed(world_root, "chunk world root")
	assert_no_new_orphans()