extends GutTest
## Tests for GCStreamChunkSource: lifecycle, spawning, despawning.

var _source: GCStreamChunkSource
var _controller: GCWorldController
var _context: GCGameContext


func _make_chunk_data(cat: StringName, length: float = 200.0, connector := false) -> GCChunkData:
	var data := GCChunkData.new()
	data.category = cat
	data.length = length
	data.is_connector = connector
	data.scene = _make_simple_scene()
	return data


func _make_simple_scene() -> PackedScene:
	var node := Node2D.new()
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene


func before_each() -> void:
	_context = autofree(GCGameContext.new())
	_controller = GCWorldController.new()
	add_child_autoqfree(_controller)
	_controller.set_process(false)
	_controller.set_physics_process(false)
	_controller.configure(_context)

	_source = GCStreamChunkSource.new()
	_source.buffer_between = 32.0
	_source.lookahead_count = 2
	_source.trail_count = 1
	_source.connector_interval = 0  # Disable auto-connectors for most tests


func test_open_creates_chunk_root() -> void:
	_source.chunks = [_make_chunk_data(&"a")]
	_source.open(_context, _controller, {})
	var root := _source.get_chunk_root()
	assert_not_null(root)
	assert_eq(root.name, "ChunkRoot")
	assert_eq(root.get_parent(), _controller)
	_source.close(_context, _controller)


func test_populate_spawns_lookahead_plus_one() -> void:
	_source.chunks = [_make_chunk_data(&"a"), _make_chunk_data(&"b")]
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	var root := _source.get_chunk_root()
	# lookahead_count=2, so should spawn 3 chunks (2+1)
	assert_eq(root.get_child_count(), 3)
	_source.close(_context, _controller)


func test_chunks_positioned_sequentially() -> void:
	var data := _make_chunk_data(&"a", 200.0)
	_source.chunks = [data]
	_source.buffer_between = 50.0
	_source.lookahead_count = 2
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	var root := _source.get_chunk_root()
	var first: Node2D = root.get_child(0)
	var second: Node2D = root.get_child(1)
	var third: Node2D = root.get_child(2)
	assert_eq(first.position.y, 0.0)
	assert_eq(second.position.y, 250.0)  # 200 length + 50 buffer
	assert_eq(third.position.y, 500.0)
	_source.close(_context, _controller)


func test_close_resets_state() -> void:
	_source.chunks = [_make_chunk_data(&"a")]
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	_source.close(_context, _controller)
	assert_eq(_source.get_loaded_chunks().size(), 0)
	assert_eq(_source.get_chunks_spawned(), 0)


func test_chunk_spawned_signal_emitted() -> void:
	_source.chunks = [_make_chunk_data(&"test_cat")]
	_source.lookahead_count = 0
	watch_signals(_source)
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	assert_signal_emitted(_source, "chunk_spawned")
	var params = get_signal_parameters(_source, "chunk_spawned", 0)
	assert_not_null(params)
	assert_not_null(params[0])  # chunk_node
	assert_eq(params[2], 0)    # index
	_source.close(_context, _controller)


func test_connector_spawned_signal_emitted() -> void:
	var connector := _make_chunk_data(&"rest", 100.0, true)
	var challenge := _make_chunk_data(&"fight", 200.0)
	_source.chunks = [challenge]
	_source.connectors = [connector]
	_source.connector_interval = 1  # Insert connector after every challenge
	_source.lookahead_count = 1
	watch_signals(_source)
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	# First chunk is challenge, then connector after interval
	assert_signal_emitted(_source, "connector_spawned")
	_source.close(_context, _controller)


func test_history_tracking() -> void:
	var a := _make_chunk_data(&"alpha")
	var b := _make_chunk_data(&"beta")
	_source.chunks = [a, b]
	_source.lookahead_count = 1
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	# After spawning, chunks_spawned should be lookahead_count + 1
	assert_eq(_source.get_chunks_spawned(), 2)
	_source.close(_context, _controller)


func test_get_loaded_chunks_returns_array() -> void:
	_source.chunks = [_make_chunk_data(&"a")]
	_source.lookahead_count = 0
	_source.open(_context, _controller, {})
	_source.populate(_context, _controller, {})
	var loaded := _source.get_loaded_chunks()
	assert_eq(loaded.size(), 1)
	assert_eq(loaded[0].index, 0)
	assert_not_null(loaded[0].node)
	assert_not_null(loaded[0].data)
	_source.close(_context, _controller)
