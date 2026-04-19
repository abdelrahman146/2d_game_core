extends RefCounted
class_name GCService
## Base class for all services. Extend this to create reusable services
## like save/load, audio, input, multiplayer, etc.

var context: GCGameContext
var is_running := false


func start(_context: GCGameContext) -> void:
	context = _context
	is_running = true


func stop() -> void:
	is_running = false
	context = null
