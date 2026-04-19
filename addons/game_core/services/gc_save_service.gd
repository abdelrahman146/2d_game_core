extends GCService
class_name GCSaveService
## Handles saving and loading game state.
## Uses local JSON files by default. Override _write/_read for custom backends.

signal game_saved(slot_id: String)
signal game_loaded(slot_id: String)

@export var save_dir := "user://saves/"


func save_game(slot_id: String) -> bool:
	var data := {
		&"context": context.serialize(),
		&"timestamp": Time.get_unix_time_from_system(),
	}
	return _write(slot_id, data)


func load_game(slot_id: String) -> bool:
	var data := _read(slot_id)
	if data.is_empty():
		return false
	if data.has(&"context"):
		context.deserialize(data[&"context"])
	game_loaded.emit(slot_id)
	return true


func has_save(slot_id: String) -> bool:
	return FileAccess.file_exists(_path_for(slot_id))


func delete_save(slot_id: String) -> void:
	var path := _path_for(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func list_saves() -> PackedStringArray:
	var saves := PackedStringArray()
	var dir := DirAccess.open(save_dir)
	if dir == null:
		return saves
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.ends_with(".save"):
			saves.append(file_name.get_basename())
		file_name = dir.get_next()
	return saves


func _write(slot_id: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var path := _path_for(slot_id)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GCSaveService: Cannot write to '%s'." % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	game_saved.emit(slot_id)
	return true


func _read(slot_id: String) -> Dictionary:
	var path := _path_for(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("GCSaveService: Failed to parse save file '%s'." % path)
		return {}
	return json.data if json.data is Dictionary else {}


func _path_for(slot_id: String) -> String:
	return save_dir.path_join(slot_id + ".save")
