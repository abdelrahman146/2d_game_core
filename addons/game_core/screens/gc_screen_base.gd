extends Node
class_name GCScreenBase

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCScreenDefinition = preload("res://addons/game_core/screens/gc_screen_definition.gd")

signal transition_requested(screen_id: StringName, payload: Dictionary)

var context: GCGameContext
var screen_definition: GCScreenDefinition


func setup_screen(game_context: GCGameContext, definition: GCScreenDefinition) -> void:
	context = game_context
	screen_definition = definition


func enter(_payload: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func request_transition(screen_id: StringName, payload: Dictionary = {}) -> void:
	transition_requested.emit(screen_id, payload)
