extends Node
class_name GCWorldController
## Manages world lifecycle: open, close, transition between levels/rooms/chunks.
## Assign a GCWorldSource in the inspector to define loading strategy.

signal world_opened(payload: Dictionary)
signal world_closed
signal level_changed(level_id: Variant)

@export var source: GCWorldSource

var context: GCGameContext
var is_open := false
var world_root: Node
var current_level_id: Variant


func configure(game_context: GCGameContext) -> void:
	context = game_context


func open_world(payload: Dictionary = {}) -> void:
	if source == null:
		push_warning("GCWorldController: No world source assigned.")
		return
	if context == null:
		push_error("GCWorldController: Must be configured before opening.")
		return
	if is_open:
		close_world()
	source.open(context, self, payload)
	source.populate(context, self, payload)
	is_open = true
	world_opened.emit(payload)


func close_world() -> void:
	if not is_open:
		return
	if source:
		source.close(context, self)
	_clear_root()
	is_open = false
	world_closed.emit()


func load_level(level_id: Variant, payload: Dictionary = {}) -> void:
	current_level_id = level_id
	payload[&"level_id"] = level_id
	if is_open:
		close_world()
	open_world(payload)
	level_changed.emit(level_id)


func set_world_root(node: Node) -> void:
	_clear_root()
	world_root = node
	if world_root and world_root.get_parent() != self:
		add_child(world_root)


func get_world_root() -> Node:
	return world_root


func _clear_root() -> void:
	if world_root == null:
		return
	if world_root.get_parent() == self:
		remove_child(world_root)
	if is_instance_valid(world_root):
		world_root.queue_free()
	world_root = null
