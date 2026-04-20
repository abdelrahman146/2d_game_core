extends GutTest
## Tests for GCChunkData resource.


func test_default_values() -> void:
	var data := GCChunkData.new()
	assert_null(data.scene)
	assert_eq(data.category, &"")
	assert_eq(data.difficulty, 0.0)
	assert_eq(data.length, 320.0)
	assert_false(data.is_connector)
	assert_eq(data.tags.size(), 0)
	assert_eq(data.connects_from.size(), 0)
	assert_eq(data.connects_to.size(), 0)


func test_set_properties() -> void:
	var data := GCChunkData.new()
	data.category = &"drones"
	data.difficulty = 0.7
	data.length = 512.0
	data.is_connector = true
	data.tags = [&"has_walls", &"no_platforms"]
	data.connects_from = [&"falling_boxes"]
	data.connects_to = [&"gates", &"drones"]
	assert_eq(data.category, &"drones")
	assert_eq(data.difficulty, 0.7)
	assert_eq(data.length, 512.0)
	assert_true(data.is_connector)
	assert_eq(data.tags.size(), 2)
	assert_eq(data.tags[0], &"has_walls")
	assert_eq(data.tags[1], &"no_platforms")
	assert_eq(data.connects_from[0], &"falling_boxes")
	assert_eq(data.connects_to[0], &"gates")
	assert_eq(data.connects_to[1], &"drones")
