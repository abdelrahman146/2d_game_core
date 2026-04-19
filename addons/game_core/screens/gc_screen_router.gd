extends Node
class_name GCScreenRouter

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCScreenBase = preload("res://addons/game_core/screens/gc_screen_base.gd")
const GCScreenDefinition = preload("res://addons/game_core/screens/gc_screen_definition.gd")

signal transitioned(previous_screen: StringName, next_screen: StringName)

@export var definitions: Array[GCScreenDefinition] = []

var context: GCGameContext
var current_screen: GCScreenBase
var current_screen_id: StringName
var _definitions_by_id: Dictionary = {}
var _persistent_instances: Dictionary = {}


func configure(game_context: GCGameContext) -> void:
	context = game_context
	_rebuild_definition_cache()


func go_to(screen_id: StringName, payload: Dictionary = {}) -> void:
	if context == null:
		push_error("GCScreenRouter must be configured before go_to is called.")
		return
	if not _definitions_by_id.has(screen_id):
		push_error("Unknown screen id '%s'." % screen_id)
		return
	var definition: GCScreenDefinition = _definitions_by_id[screen_id]
	var next_screen := _get_or_create_screen(definition)
	if next_screen == null:
		return
	var transition_resource := definition.transition
	if transition_resource == null:
		complete_transition(current_screen, next_screen, payload)
		return
	transition_resource.begin(self, current_screen, next_screen, payload)


func complete_transition(from_screen: GCScreenBase, to_screen: GCScreenBase, payload: Dictionary = {}) -> void:
	var previous_id := current_screen_id
	if from_screen != null:
		_release_screen(from_screen, true, not _is_persistent_screen(from_screen.screen_definition))
	current_screen = to_screen
	current_screen_id = to_screen.screen_definition.id
	if current_screen.get_parent() != self:
		add_child(current_screen)
	if not current_screen.transition_requested.is_connected(_on_screen_transition_requested):
		current_screen.transition_requested.connect(_on_screen_transition_requested)
	current_screen.enter(payload)
	transitioned.emit(previous_id, current_screen_id)


func _get_or_create_screen(definition: GCScreenDefinition) -> GCScreenBase:
	if definition.is_persistent and _persistent_instances.has(definition.id):
		return _persistent_instances[definition.id]
	var screen := definition.instantiate_screen(context)
	if screen == null:
		return null
	if definition.is_persistent:
		_persistent_instances[definition.id] = screen
	return screen


func _rebuild_definition_cache() -> void:
	_definitions_by_id.clear()
	for definition in definitions:
		if definition == null or definition.id.is_empty():
			continue
		_definitions_by_id[definition.id] = definition


func reset_router() -> void:
	if current_screen != null:
		_release_screen(current_screen, true, true)
	for screen in _persistent_instances.values():
		var cached_screen := screen as GCScreenBase
		if cached_screen == null or cached_screen == current_screen:
			continue
		_release_screen(cached_screen, false, true)
	_persistent_instances.clear()
	current_screen = null
	current_screen_id = StringName()
	context = null


func _is_persistent_screen(definition: GCScreenDefinition) -> bool:
	return definition != null and definition.is_persistent


func _on_screen_transition_requested(screen_id: StringName, payload: Dictionary = {}) -> void:
	go_to(screen_id, payload)


func _release_screen(screen: GCScreenBase, should_exit: bool, should_free: bool) -> void:
	if screen == null:
		return
	if screen.transition_requested.is_connected(_on_screen_transition_requested):
		screen.transition_requested.disconnect(_on_screen_transition_requested)
	if should_exit:
		screen.exit()
	if screen.get_parent() == self:
		remove_child(screen)
	if should_free:
		screen.queue_free()
