extends Resource
class_name GCScreenDefinition

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCScreenBase = preload("res://addons/game_core/screens/gc_screen_base.gd")
const GCScreenTransition = preload("res://addons/game_core/screens/gc_screen_transition.gd")

@export var id: StringName
@export var scene: PackedScene
@export var transition: GCScreenTransition
@export var is_persistent := false


func is_valid_definition() -> bool:
	if id.is_empty():
		push_warning("Skipping GCScreenDefinition with an empty id.")
		return false
	if scene == null:
		push_warning("GCScreenDefinition '%s' has no scene assigned." % id)
		return false
	return true


func instantiate_screen(game_context: GCGameContext) -> GCScreenBase:
	if not is_valid_definition():
		return null
	var screen := scene.instantiate()
	if screen is GCScreenBase:
		(screen as GCScreenBase).setup_screen(game_context, self)
		return screen as GCScreenBase
	push_warning("Scene for GCScreenDefinition '%s' must inherit GCScreenBase." % id)
	if screen is Node:
		(screen as Node).queue_free()
	return null
