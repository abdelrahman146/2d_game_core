extends RefCounted
class_name GCGameContext
## Shared game state container accessible from the bootstrap autoload.
## Holds runtime state, player data, and metadata.

signal state_changed(key: StringName, value: Variant)
signal player_data_changed(key: StringName, value: Variant)

var state: Dictionary = {}
var player_data: Dictionary = {}
var metadata: Dictionary = {}


func set_value(key: StringName, value: Variant) -> void:
	state[key] = value
	state_changed.emit(key, value)


func get_value(key: StringName, default: Variant = null) -> Variant:
	return state.get(key, default)


func has_value(key: StringName) -> bool:
	return state.has(key)


func clear_value(key: StringName) -> void:
	state.erase(key)


func set_player_value(key: StringName, value: Variant) -> void:
	player_data[key] = value
	player_data_changed.emit(key, value)


func get_player_value(key: StringName, default: Variant = null) -> Variant:
	return player_data.get(key, default)


func has_player_value(key: StringName) -> bool:
	return player_data.has(key)


func clear() -> void:
	state.clear()
	player_data.clear()
	metadata.clear()


func serialize() -> Dictionary:
	return {
		&"state": state.duplicate(true),
		&"player_data": player_data.duplicate(true),
		&"metadata": metadata.duplicate(true),
	}


func deserialize(data: Dictionary) -> void:
	state = data.get(&"state", {}).duplicate(true)
	player_data = data.get(&"player_data", {}).duplicate(true)
	metadata = data.get(&"metadata", {}).duplicate(true)
