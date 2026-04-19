extends "res://addons/game_core/world/gc_world_source.gd"
class_name GCChunkSource
## Procedural/streaming chunk source. Manages chunk lifecycle for endless
## or procedurally generated games (roguelite, endless runners, etc.).

signal chunk_loaded(chunk: Node, index: int)
signal chunk_unloaded(index: int)

@export var chunk_scenes: Array[PackedScene] = []
@export var buffer_ahead := 2
@export var buffer_behind := 1
@export var chunk_size := Vector2(640, 360)
@export var direction := Vector2.RIGHT  ## Scroll/spawn direction

var _loaded_chunks: Array[Dictionary] = []  # [{node, index}]
var _next_index := 0
var _root: Node


func open(_context: GCGameContext, controller: GCWorldController, _payload: Dictionary = {}) -> void:
	_root = Node2D.new()
	_root.name = "ChunkRoot"
	controller.set_world_root(_root)
	_next_index = 0
	_loaded_chunks.clear()


func populate(_context: GCGameContext, _controller: GCWorldController, _payload: Dictionary = {}) -> void:
	for i in range(buffer_ahead + 1):
		_spawn_next_chunk()


func close(_context: GCGameContext, _controller: GCWorldController) -> void:
	_loaded_chunks.clear()
	_next_index = 0


func advance() -> Node:
	_spawn_next_chunk()
	_trim_behind()
	return _loaded_chunks.back().node if not _loaded_chunks.is_empty() else null


func _spawn_next_chunk() -> void:
	if chunk_scenes.is_empty():
		return
	var scene: PackedScene = chunk_scenes[_next_index % chunk_scenes.size()]
	var instance := scene.instantiate()
	instance.position = direction * chunk_size * _next_index
	if _root:
		_root.add_child(instance)
	_loaded_chunks.append({&"node": instance, &"index": _next_index})
	chunk_loaded.emit(instance, _next_index)
	_next_index += 1


func _trim_behind() -> void:
	while _loaded_chunks.size() > buffer_ahead + buffer_behind + 1:
		var old: Dictionary = _loaded_chunks.pop_front()
		chunk_unloaded.emit(old.index)
		if is_instance_valid(old.node):
			(old.node as Node).queue_free()
