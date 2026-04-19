extends Node
class_name GCWorldController

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCWorldSource = preload("res://addons/game_core/world/gc_world_source.gd")

signal world_opened(payload: Dictionary)
signal world_closed
signal world_root_changed(world_root: Node)

@export var source: GCWorldSource

var context: GCGameContext
var is_open := false
var world_root: Node


func configure(game_context: GCGameContext) -> void:
	context = game_context


func open_world(payload: Dictionary = {}) -> void:
	if source == null:
		push_warning("GCWorldController has no source configured.")
		return
	if context == null:
		push_error("GCWorldController must be configured before opening a world.")
		return
	if is_open:
		close_world()
	source.open_world(context, self, payload)
	source.populate(context, self, payload)
	is_open = true
	world_opened.emit(payload)


func close_world() -> void:
	if not is_open:
		return
	if source != null:
		source.close_world(context, self)
	clear_world_root()
	is_open = false
	world_closed.emit()


func set_world_root(next_world_root: Node) -> void:
	if world_root == next_world_root:
		if world_root != null and world_root.get_parent() != self:
			add_child(world_root)
		return
	clear_world_root()
	world_root = next_world_root
	if world_root != null and world_root.get_parent() != self:
		add_child(world_root)
	world_root_changed.emit(world_root)


func get_world_root() -> Node:
	return world_root


func clear_world_root() -> void:
	if world_root == null:
		return
	if world_root.get_parent() == self:
		remove_child(world_root)
	if is_instance_valid(world_root) and not world_root.is_queued_for_deletion():
		world_root.queue_free()
	world_root = null
	world_root_changed.emit(null)
