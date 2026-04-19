extends RefCounted
class_name GCServiceRegistry

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCService = preload("res://addons/game_core/core/gc_service.gd")

var _services: Dictionary = {}
var _setup_order: Array[StringName] = []
var _started_services: Dictionary = {}
var _current_context_ref: WeakRef
var _is_setup := false


func register_service(id: StringName, service: GCService) -> void:
	if id.is_empty():
		push_error("GCServiceRegistry.register_service requires a non-empty id.")
		return
	if service == null:
		push_error("GCServiceRegistry.register_service received a null service.")
		return
	if _services.has(id):
		var previous_service: GCService = _services[id]
		if _started_services.get(id, false):
			previous_service.teardown()
		push_warning("Replacing registered service '%s'." % id)
		_setup_order.erase(id)
		_started_services.erase(id)
	_services[id] = service
	_setup_order.append(id)
	_started_services[id] = false
	var current_context := _get_current_context()
	if _is_setup and current_context != null:
		service.setup(current_context)
		_started_services[id] = true


func has_service(id: StringName) -> bool:
	return _services.has(id)


func get_service(id: StringName) -> GCService:
	return _services.get(id) as GCService


func unregister_service(id: StringName) -> void:
	if not _services.has(id):
		return
	var service: GCService = _services[id]
	if _started_services.get(id, false):
		service.teardown()
	_services.erase(id)
	_setup_order.erase(id)
	_started_services.erase(id)


func setup_all(context: GCGameContext) -> void:
	if context == null:
		push_error("GCServiceRegistry.setup_all requires a valid GCGameContext.")
		return
	_current_context_ref = weakref(context)
	_is_setup = true
	for id in _setup_order:
		if _started_services.get(id, false):
			continue
		var service: GCService = _services[id]
		service.setup(context)
		_started_services[id] = true


func teardown_all() -> void:
	for index in range(_setup_order.size() - 1, -1, -1):
		var id: StringName = _setup_order[index]
		var service: GCService = _services[id]
		if _started_services.get(id, false):
			service.teardown()
	_services.clear()
	_setup_order.clear()
	_started_services.clear()
	_current_context_ref = null
	_is_setup = false


func list_services() -> Array[StringName]:
	return _setup_order.duplicate()


func _get_current_context() -> GCGameContext:
	if _current_context_ref == null:
		return null
	return _current_context_ref.get_ref() as GCGameContext
