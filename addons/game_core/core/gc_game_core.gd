extends Node
class_name GCGameCore

const GCGameContext = preload("res://addons/game_core/core/gc_game_context.gd")
const GCService = preload("res://addons/game_core/core/gc_service.gd")
const GCScreenRouter = preload("res://addons/game_core/screens/gc_screen_router.gd")

signal bootstrapped(context: GCGameContext)
signal shutting_down

@export var bootstrap_services: Array[Script] = []
@export var initial_screen: StringName
@export var auto_bootstrap := true

var context: GCGameContext
var screen_router: Node
var _is_bootstrapped := false


func _ready() -> void:
	if auto_bootstrap:
		bootstrap()


func _exit_tree() -> void:
	shutdown()


func bootstrap() -> void:
	if _is_bootstrapped:
		return
	if context == null:
		context = GCGameContext.new()
	_register_bootstrap_services()
	context.services.setup_all(context)
	screen_router = _resolve_screen_router()
	if screen_router != null:
		screen_router.configure(context)
		if not initial_screen.is_empty():
			screen_router.go_to(initial_screen)
	_is_bootstrapped = true
	bootstrapped.emit(context)


func shutdown() -> void:
	if not _is_bootstrapped or context == null:
		return
	shutting_down.emit()
	if screen_router is GCScreenRouter:
		(screen_router as GCScreenRouter).reset_router()
	context.services.teardown_all()
	context = null
	screen_router = null
	_is_bootstrapped = false


func register_service(id: StringName, service: GCService) -> void:
	if context == null:
		if _is_bootstrapped:
			push_error("GCGameCore context is unexpectedly missing.")
			return
		context = GCGameContext.new()
	context.services.register_service(id, service)


func _register_bootstrap_services() -> void:
	for script_resource in bootstrap_services:
		if script_resource == null:
			continue
		var service_instance: Variant = script_resource.new()
		if service_instance is GCService:
			var service_id := _service_id_from_script(script_resource)
			context.services.register_service(service_id, service_instance)
		else:
			push_warning("Bootstrap service script '%s' does not inherit GCService." % script_resource.resource_path)


func _resolve_screen_router() -> Node:
	for child in get_children():
		if child is GCScreenRouter:
			return child as Node
	return null


func _service_id_from_script(script_resource: Script) -> StringName:
	var path := script_resource.resource_path.get_file().get_basename()
	if path.is_empty():
		return &"service"
	return StringName(path.to_snake_case())
