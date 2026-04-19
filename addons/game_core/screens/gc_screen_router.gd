extends CanvasLayer
class_name GCScreenRouter
## Manages screen navigation with stack support and animated transitions.
## Add as a child of GCBootstrap or any node. Configure screen definitions in inspector.

const _ScreenDef = preload("res://addons/game_core/screens/gc_screen_def.gd")
const _Screen = preload("res://addons/game_core/screens/gc_screen.gd")
const _Transition = preload("res://addons/game_core/screens/transitions/gc_transition.gd")

signal screen_changed(screen_id: StringName)

@export var definitions: Array[_ScreenDef] = []
@export var default_transition: _Transition

var context: GCGameContext
var current_screen: _Screen
var current_id: StringName

var _stack: Array[Dictionary] = []  # [{id, payload}]
var _persistent_cache: Dictionary = {}  # id -> GCScreen
var _is_transitioning := false


func configure(game_context: GCGameContext) -> void:
	context = game_context


func go_to(screen_id: StringName, payload: Dictionary = {}) -> void:
	if _is_transitioning:
		return
	_stack.clear()
	_navigate_to(screen_id, payload)


func push(screen_id: StringName, payload: Dictionary = {}) -> void:
	if _is_transitioning:
		return
	if current_screen != null:
		_stack.append({&"id": current_id, &"payload": {}})
		current_screen.pause()
	_navigate_to(screen_id, payload)


func back(payload: Dictionary = {}) -> void:
	if _is_transitioning:
		return
	if _stack.is_empty():
		return
	var prev: Dictionary = _stack.pop_back()
	_navigate_to(prev.id, payload if not payload.is_empty() else prev.get(&"payload", {}))


func can_go_back() -> bool:
	return not _stack.is_empty()


func _navigate_to(screen_id: StringName, payload: Dictionary) -> void:
	var def: _ScreenDef = _find_def(screen_id)
	if def == null:
		push_error("GCScreenRouter: No screen defined for id '%s'." % screen_id)
		return

	var transition: _Transition = def.transition if def.transition else default_transition
	_is_transitioning = true

	if transition and current_screen:
		transition.play_exit(self)
		await transition.finished
	
	_remove_current()

	var next_screen: _Screen = _get_or_create_screen(def)
	if next_screen == null:
		_is_transitioning = false
		return

	current_screen = next_screen
	current_id = screen_id
	add_child(current_screen)
	current_screen.setup(context)
	current_screen.enter(payload)

	if transition:
		transition.play_enter(self)
		await transition.finished

	_is_transitioning = false
	screen_changed.emit(screen_id)


func _remove_current() -> void:
	if current_screen == null:
		return
	current_screen.exit()
	var def: _ScreenDef = _find_def(current_id)
	if def and def.is_persistent:
		remove_child(current_screen)
	else:
		current_screen.queue_free()
	current_screen = null
	current_id = &""


func _get_or_create_screen(def: _ScreenDef) -> _Screen:
	if def.is_persistent and _persistent_cache.has(def.id):
		return _persistent_cache[def.id]
	if def.scene == null:
		push_error("GCScreenRouter: Screen '%s' has no scene assigned." % def.id)
		return null
	var instance: Node = def.scene.instantiate()
	if instance is _Screen:
		if def.is_persistent:
			_persistent_cache[def.id] = instance
		return instance as _Screen
	push_error("GCScreenRouter: Scene root for '%s' must extend GCScreen." % def.id)
	instance.queue_free()
	return null


func _find_def(screen_id: StringName) -> _ScreenDef:
	for def in definitions:
		if def and def.id == screen_id:
			return def
	return null
