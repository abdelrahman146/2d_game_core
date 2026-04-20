extends GutTest
## Tests for GCChunkSelector base resource.


func _make_chunk(cat: StringName, from: Array[StringName] = []) -> GCChunkData:
	var data := GCChunkData.new()
	data.category = cat
	data.connects_from = from
	return data


func test_select_next_returns_from_pool() -> void:
	var selector := GCChunkSelector.new()
	var a := _make_chunk(&"alpha")
	var b := _make_chunk(&"beta")
	var pool: Array = [a, b]
	var result := selector.select_next(pool, [], {})
	assert_not_null(result)
	assert_true(result == a or result == b)


func test_select_next_returns_null_for_empty_pool() -> void:
	var selector := GCChunkSelector.new()
	var result := selector.select_next([], [], {})
	assert_null(result)


func test_filter_pool_accepts_all_when_no_history() -> void:
	var selector := GCChunkSelector.new()
	var a := _make_chunk(&"alpha")
	var b := _make_chunk(&"beta", [&"gamma"])
	var pool: Array = [a, b]
	var filtered := selector.filter_pool(pool, [], {})
	assert_eq(filtered.size(), 2)


func test_filter_pool_respects_connects_from() -> void:
	var selector := GCChunkSelector.new()
	var a := _make_chunk(&"alpha")  # No restriction
	var b := _make_chunk(&"beta", [&"gamma"])  # Only after "gamma"
	var c := _make_chunk(&"delta", [&"alpha", &"gamma"])  # After "alpha" or "gamma"
	var pool: Array = [a, b, c]
	var history: Array[StringName] = [&"alpha"]
	var filtered := selector.filter_pool(pool, history, {})
	# a has no restriction → passes
	# b requires gamma predecessor → blocked
	# c accepts alpha → passes
	assert_eq(filtered.size(), 2)
	assert_true(filtered.has(a))
	assert_false(filtered.has(b))
	assert_true(filtered.has(c))


func test_filter_pool_empty_connects_from_means_any() -> void:
	var selector := GCChunkSelector.new()
	var a := _make_chunk(&"open")  # No restriction (empty connects_from)
	var pool: Array = [a]
	var history: Array[StringName] = [&"anything"]
	var filtered := selector.filter_pool(pool, history, {})
	assert_eq(filtered.size(), 1)
	assert_true(filtered.has(a))


func test_select_next_falls_back_to_full_pool_if_filter_empty() -> void:
	var selector := GCChunkSelector.new()
	# Only chunk requires "xyz" predecessor which doesn't match history
	var a := _make_chunk(&"locked", [&"xyz"])
	var pool: Array = [a]
	var history: Array[StringName] = [&"other"]
	# filter_pool would return empty, select_next should fall back to full pool
	var result := selector.select_next(pool, history, {})
	assert_eq(result, a)
