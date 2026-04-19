extends RefCounted
class_name GCServiceRegistry
## Manages ordered registration, startup, lookup, and shutdown of services.

var _services: Array[Dictionary] = []  # [{id, service}]
var _is_running := false
var _context: GCGameContext


func register(id: StringName, service: GCService) -> void:
	for entry in _services:
		if entry.id == id:
			push_warning("Service '%s' already registered. Replacing." % id)
			if entry.service.is_running:
				entry.service.stop()
			entry.service = service
			if _is_running:
				service.start(_context)
			return
	_services.append({&"id": id, &"service": service})
	if _is_running:
		service.start(_context)


func start_all(context: GCGameContext) -> void:
	_context = context
	_is_running = true
	for entry in _services:
		if not entry.service.is_running:
			entry.service.start(context)


func stop_all() -> void:
	for i in range(_services.size() - 1, -1, -1):
		if _services[i].service.is_running:
			_services[i].service.stop()
	_is_running = false
	_context = null


func get_service(id: StringName) -> GCService:
	for entry in _services:
		if entry.id == id:
			return entry.service
	return null


func has_service(id: StringName) -> bool:
	return get_service(id) != null


func get_all_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for entry in _services:
		ids.append(entry.id)
	return ids
