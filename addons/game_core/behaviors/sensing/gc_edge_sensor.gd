extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCEdgeSensor
## Detects floor edges ahead using a RayCast2D child.
## Writes "edge_ahead" (bool) to local_state.

@export var raycast_path: NodePath


func _init() -> void:
	phase = Phase.SENSE


func on_physics(host: Node, _delta: float) -> void:
	var ray := _get_raycast(host)
	if ray == null:
		return
	# Flip ray to match facing direction
	var facing: int = host.local_state.get(&"facing_direction", 1)
	ray.position.x = abs(ray.position.x) * facing
	host.local_state[&"edge_ahead"] = not ray.is_colliding()


func _get_raycast(host: Node) -> RayCast2D:
	if not raycast_path.is_empty():
		var node := host.get_node_or_null(raycast_path)
		if node is RayCast2D:
			return node as RayCast2D
	# Fallback: find first RayCast2D child named "FloorProbe" or "EdgeProbe"
	for child in host.get_children():
		if child is RayCast2D and (child.name == "FloorProbe" or child.name == "EdgeProbe"):
			return child as RayCast2D
	return null
