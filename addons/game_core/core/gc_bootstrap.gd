extends Node
class_name GCBootstrap
## The single autoload entry point for the game core.
## Add this as an autoload named "GCBootstrap" in Project Settings.
## It creates the game context, starts services, and provides global access.

signal ready_completed
signal shutting_down

@export var service_scripts: Array[Script] = []

var context: GCGameContext
var services: GCServiceRegistry
var router: Node  # GCScreenRouter, resolved at runtime
var paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	context = GCGameContext.new()
	services = GCServiceRegistry.new()
	_register_services()
	services.start_all(context)
	router = _find_router()
	ready_completed.emit()


func _exit_tree() -> void:
	shutting_down.emit()
	services.stop_all()


func pause_game() -> void:
	paused = true
	get_tree().paused = true


func unpause_game() -> void:
	paused = false
	get_tree().paused = false


func restart_scene() -> void:
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().quit()


func get_service(id: StringName) -> GCService:
	return services.get_service(id)


func _register_services() -> void:
	for script in service_scripts:
		if script == null:
			continue
		var instance = script.new()
		if instance is GCService:
			var id := _id_from_script(script)
			services.register(id, instance)
		else:
			push_warning("Script '%s' does not extend GCService." % script.resource_path)


func _find_router() -> Node:
	for child in get_children():
		if child.has_method("go_to"):
			return child
	return null


func _id_from_script(script: Script) -> StringName:
	var path := script.resource_path.get_file().get_basename()
	return StringName(path.to_snake_case()) if not path.is_empty() else &"service"
