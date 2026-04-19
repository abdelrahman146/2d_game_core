extends "res://addons/game_core/world/gc_world_source.gd"
class_name GCChunkSequenceWorldSource

@export var chunk_scenes: Array = []
@export var root_name: StringName = &"world_chunks"


func open_world(_context: GCGameContext, controller: GCWorldController, _payload: Dictionary = {}) -> void:
	var root := Node.new()
	root.name = String(root_name)
	controller.set_world_root(root)


func close_world(_context: GCGameContext, _controller: GCWorldController) -> void:
	pass


func populate(_context: GCGameContext, controller: GCWorldController, payload: Dictionary = {}) -> void:
	var root := _ensure_root(controller)
	for chunk_scene in _resolve_chunk_scenes(payload):
		_append_chunk(root, chunk_scene)


func append_chunk(controller: GCWorldController, chunk_scene: PackedScene) -> Node:
	var root := _ensure_root(controller)
	return _append_chunk(root, chunk_scene)


func trim_chunks(controller: GCWorldController, keep_count: int, trim_from_front := true) -> void:
	var root := controller.get_world_root()
	if root == null:
		return
	var clamped_keep_count := maxi(keep_count, 0)
	while root.get_child_count() > clamped_keep_count:
		var index := 0 if trim_from_front else root.get_child_count() - 1
		var chunk := root.get_child(index)
		root.remove_child(chunk)
		(chunk as Node).queue_free()


func get_loaded_chunks(controller: GCWorldController) -> Array[Node]:
	var root := controller.get_world_root()
	if root == null:
		return []
	var chunks: Array[Node] = []
	for child in root.get_children():
		chunks.append(child as Node)
	return chunks


func _ensure_root(controller: GCWorldController) -> Node:
	var root := controller.get_world_root()
	if root != null:
		return root
	open_world(null, controller, {})
	return controller.get_world_root()


func _resolve_chunk_scenes(payload: Dictionary) -> Array[PackedScene]:
	if payload.has(&"chunks") and payload[&"chunks"] is Array:
		return _filter_chunk_scenes(payload[&"chunks"] as Array)
	return _filter_chunk_scenes(chunk_scenes)


func _filter_chunk_scenes(source_chunks: Array) -> Array[PackedScene]:
	var filtered_chunk_scenes: Array[PackedScene] = []
	for chunk_scene in source_chunks:
		if chunk_scene is PackedScene:
			filtered_chunk_scenes.append(chunk_scene as PackedScene)
	return filtered_chunk_scenes


func _append_chunk(root: Node, chunk_scene: PackedScene) -> Node:
	if chunk_scene == null:
		push_warning("GCChunkSequenceWorldSource received a null chunk scene.")
		return null
	var chunk_instance := chunk_scene.instantiate()
	if chunk_instance is Node:
		root.add_child(chunk_instance)
		return chunk_instance as Node
	push_warning("GCChunkSequenceWorldSource chunk scenes must instantiate Nodes.")
	return null