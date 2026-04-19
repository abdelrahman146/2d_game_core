extends Node
class_name GCWorldController

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCWorldSource = preload("res://addons/game_core/world/gc_world_source.gd")

signal world_opened(payload: Dictionary)
signal world_closed

@export var source: GCWorldSource

var context: GCGameContext
var is_open := false


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
	if not is_open or source == null:
		return
	source.close_world(context, self)
	is_open = false
	world_closed.emit()
