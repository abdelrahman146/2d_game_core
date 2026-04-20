extends "res://addons/game_core/world/gc_world_source.gd"
class_name GCStreamChunkSource
## Scroll-based streaming chunk source for endless/procedural games.
## Spawns chunks at the leading edge, despawns them past the trailing edge.
## Works with GCChunkData for metadata and GCChunkSelector for selection logic.

signal chunk_spawned(chunk_node: Node, chunk_data: Resource, index: int)
signal chunk_despawned(index: int)
signal connector_spawned(chunk_node: Node, chunk_data: Resource, index: int)

## Challenge chunks available for selection.
@export var chunks: Array[Resource] = []  # Array of GCChunkData

## Connector/rest chunks for transitions between challenges.
@export var connectors: Array[Resource] = []  # Array of GCChunkData

## Selection strategy. If null, uses random selection.
@export var selector: Resource  # GCChunkSelector

## Pixels of empty buffer between chunks.
@export var buffer_between: float = 64.0

## Number of challenge chunks between connector insertions.
## Set to 0 to disable automatic connector insertion.
@export var connector_interval: int = 4

## How many chunks to keep loaded ahead of the despawn edge.
@export var lookahead_count: int = 3

## How many chunks behind the viewport to keep before despawning.
@export var trail_count: int = 1

var _root: Node2D
var _loaded: Array[Dictionary] = []  # [{node, data, index, end_offset}]
var _next_index: int = 0
var _since_last_connector: int = 0
var _spawn_offset: float = 0.0  # Next spawn position along scroll axis
var _history: Array[StringName] = []
var _chunks_spawned: int = 0
var _elapsed: float = 0.0


func open(_context: GCGameContext, controller: GCWorldController, _payload: Dictionary = {}) -> void:
	_root = Node2D.new()
	_root.name = "ChunkRoot"
	controller.set_world_root(_root)
	_reset()


func populate(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	for i in range(lookahead_count + 1):
		_spawn_next()


func close(_context: GCGameContext, _controller: GCWorldController) -> void:
	_loaded.clear()
	_reset()


## Call each physics frame to manage chunk lifecycle.
## [param viewport_start]: The leading edge position (e.g., bottom of screen in Y scroll).
## [param viewport_end]: The trailing edge position (e.g., top of screen in Y scroll).
## [param scroll_axis_size]: Viewport size along scroll axis.
func update(viewport_start: float, viewport_end: float, scroll_axis_size: float) -> void:
	# Despawn chunks fully past the trailing edge
	_despawn_trailing(viewport_end)
	# Spawn chunks as the leading edge approaches
	_spawn_if_needed(viewport_start, scroll_axis_size)


## Returns the root node containing all loaded chunks.
func get_chunk_root() -> Node2D:
	return _root


## Returns the array of currently loaded chunk dictionaries.
func get_loaded_chunks() -> Array[Dictionary]:
	return _loaded


## Returns total chunks spawned since open.
func get_chunks_spawned() -> int:
	return _chunks_spawned


## Advance elapsed time (called by scroll driver or externally).
func advance_time(delta: float) -> void:
	_elapsed += delta


func _reset() -> void:
	_next_index = 0
	_since_last_connector = 0
	_spawn_offset = 0.0
	_history.clear()
	_chunks_spawned = 0
	_elapsed = 0.0


func _spawn_next() -> void:
	var data: Resource = _pick_next()
	if data == null:
		return
	_do_spawn(data)


func _pick_next() -> Resource:
	# Determine if a connector should be inserted
	if _should_insert_connector():
		var connector := _select_from(connectors)
		if connector:
			_since_last_connector = 0
			return connector

	var challenge := _select_from(chunks)
	if challenge:
		_since_last_connector += 1
	return challenge


func _should_insert_connector() -> bool:
	if connector_interval <= 0:
		return false
	if connectors.is_empty():
		return false
	return _since_last_connector >= connector_interval


func _select_from(pool: Array[Resource]) -> Resource:
	if pool.is_empty():
		return null
	var context := _build_context()
	if selector:
		return selector.select_next(pool, _history, context)
	# Fallback: random
	return pool[randi() % pool.size()]


func _build_context() -> Dictionary:
	var difficulty_cursor := clampf(_elapsed / 300.0, 0.0, 1.0)  # 5 minutes to max
	var last_was_conn := false
	if not _loaded.is_empty():
		var last_data: GCChunkData = _loaded.back().data as GCChunkData
		if last_data:
			last_was_conn = last_data.is_connector
	return {
		&"elapsed_time": _elapsed,
		&"chunks_spawned": _chunks_spawned,
		&"difficulty_cursor": difficulty_cursor,
		&"last_category": _history.back() if not _history.is_empty() else &"",
		&"last_was_connector": last_was_conn,
	}


func _do_spawn(data: Resource) -> void:
	var chunk_data: GCChunkData = data as GCChunkData
	if chunk_data == null or chunk_data.scene == null:
		return
	var instance: Node = chunk_data.scene.instantiate()
	# Position along scroll axis (Y for vertical scroll)
	# Chunks spawn below the viewport (positive Y = down)
	if instance is Node2D:
		(instance as Node2D).position.y = _spawn_offset
	if _root:
		_root.add_child(instance)

	var chunk_length: float = chunk_data.length
	var entry := {
		&"node": instance,
		&"data": chunk_data,
		&"index": _next_index,
		&"start_offset": _spawn_offset,
		&"end_offset": _spawn_offset + chunk_length,
	}
	_loaded.append(entry)
	_spawn_offset += chunk_length + buffer_between
	_next_index += 1
	_chunks_spawned += 1

	# Track history
	_history.append(chunk_data.category)
	if _history.size() > 20:
		_history.pop_front()

	# Emit signals
	if chunk_data.is_connector:
		connector_spawned.emit(instance, chunk_data, entry.index)
	else:
		chunk_spawned.emit(instance, chunk_data, entry.index)


func _despawn_trailing(trailing_edge: float) -> void:
	while _loaded.size() > trail_count + 1:
		var first: Dictionary = _loaded[0]
		# Check if the chunk's end has scrolled past the trailing edge
		var node: Node2D = first.node
		if not is_instance_valid(node):
			_loaded.pop_front()
			continue
		# The node's global Y (after scrolling) tells us where it actually is
		var chunk_data: GCChunkData = first.data as GCChunkData
		var chunk_global_end: float = node.global_position.y + (chunk_data.length if chunk_data else 0.0)
		if chunk_global_end < trailing_edge:
			_loaded.pop_front()
			chunk_despawned.emit(first.index)
			node.queue_free()
		else:
			break


func _spawn_if_needed(leading_edge: float, viewport_size: float) -> void:
	# Spawn when the last chunk's end is within viewport range of the leading edge
	if _loaded.is_empty():
		_spawn_next()
		return
	var last: Dictionary = _loaded.back()
	var last_node: Node2D = last.node
	if not is_instance_valid(last_node):
		_spawn_next()
		return
	var last_end_global: float = last_node.global_position.y + last.data.length
	# If the end of the last chunk is within lookahead distance of the leading edge
	if last_end_global - leading_edge < viewport_size * lookahead_count:
		_spawn_next()
