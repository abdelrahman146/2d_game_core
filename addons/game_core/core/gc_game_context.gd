extends RefCounted
class_name GCGameContext

const GCServiceRegistry = preload("res://addons/game_core/core/gc_service_registry.gd")

const SERIALIZATION_VERSION := 1

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


func serialize() -> Dictionary:
	return {
		&"version": SERIALIZATION_VERSION,
		&"shared_state": shared_state.duplicate(true),
		&"runtime_state": runtime_state.duplicate(true),
		&"metadata": metadata.duplicate(true),
	}


func apply_serialized_data(data: Dictionary) -> void:
	shared_state = _read_serialized_dictionary(data, &"shared_state")
	runtime_state = _read_serialized_dictionary(data, &"runtime_state")
	metadata = _read_serialized_dictionary(data, &"metadata")


static func from_serialized_data(data: Dictionary) -> GCGameContext:
	var context := GCGameContext.new()
	context.apply_serialized_data(data)
	return context


func _read_serialized_dictionary(data: Dictionary, key: StringName) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
