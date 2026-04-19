extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCWallSensor
## Detects walls ahead using a RayCast2D child.
## Writes "wall_ahead" (bool) to local_state.

@export var raycast_path: NodePath


func _init() -> void:
	phase = Phase.SENSE


func on_physics(host: Node, _delta: float) -> void:
	var ray := _get_raycast(host)
	if ray == null:
		return
	# Flip ray to match facing direction
	var facing: int = host.local_state.get(&"facing_direction", 1)
	ray.target_position.x = abs(ray.target_position.x) * facing
	host.local_state[&"wall_ahead"] = ray.is_colliding()


func _get_raycast(host: Node) -> RayCast2D:
	if not raycast_path.is_empty():
		var node := host.get_node_or_null(raycast_path)
		if node is RayCast2D:
			return node as RayCast2D
	for child in host.get_children():
		if child is RayCast2D and (child.name == "WallProbe" or child.name == "WallRay"):
			return child as RayCast2D
	return null
