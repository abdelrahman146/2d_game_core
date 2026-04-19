extends GCService
class_name GCDatabaseService
## Generic async database interface. Implement a subclass for your backend.

signal request_completed(success: bool, data: Variant)


func get_document(_collection: String, _id: String) -> Dictionary:
	push_warning("GCDatabaseService: get_document not implemented.")
	return {}


func set_document(_collection: String, _id: String, _data: Dictionary) -> bool:
	push_warning("GCDatabaseService: set_document not implemented.")
	return false


func delete_document(_collection: String, _id: String) -> bool:
	push_warning("GCDatabaseService: delete_document not implemented.")
	return false


func query(_collection: String, _filters: Dictionary = {}, _limit: int = 100) -> Array:
	push_warning("GCDatabaseService: query not implemented.")
	return []
