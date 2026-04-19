extends RefCounted
class_name GCGameContext

const GCServiceRegistry = preload("res://addons/game_core/core/gc_service_registry.gd")

var services: GCServiceRegistry
var shared_state: Dictionary = {}
var runtime_state: Dictionary = {}
var metadata: Dictionary = {}


func _init() -> void:
	services = GCServiceRegistry.new()


func set_value(key: StringName, value: Variant) -> void:
	runtime_state[key] = value


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return runtime_state.get(key, default_value)


func set_shared_value(key: StringName, value: Variant) -> void:
	shared_state[key] = value


func get_shared_value(key: StringName, default_value: Variant = null) -> Variant:
	return shared_state.get(key, default_value)
