extends CanvasLayer
class_name GCHudLayer
## Persistent overlay layer for HUD elements. Lives above game screens.
## Add HUD scenes by id, show/hide them anytime.

var _elements: Dictionary = {}  # id -> Node


func add_element(id: StringName, scene: PackedScene) -> Node:
	if _elements.has(id):
		return _elements[id]
	var instance := scene.instantiate()
	instance.name = String(id)
	_elements[id] = instance
	add_child(instance)
	return instance


func add_node(id: StringName, node: Node) -> void:
	if _elements.has(id):
		return
	_elements[id] = node
	add_child(node)


func remove_element(id: StringName) -> void:
	if not _elements.has(id):
		return
	var node: Node = _elements[id]
	_elements.erase(id)
	node.queue_free()


func show_element(id: StringName) -> void:
	if _elements.has(id):
		(_elements[id] as Node).visible = true


func hide_element(id: StringName) -> void:
	if _elements.has(id):
		(_elements[id] as Node).visible = false


func get_element(id: StringName) -> Node:
	return _elements.get(id)


func clear_all() -> void:
	for node in _elements.values():
		(node as Node).queue_free()
	_elements.clear()
