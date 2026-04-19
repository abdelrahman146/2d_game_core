extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCLineSight
## Checks line of sight to a target using a RayCast2D.
## Writes "has_line_of_sight" to local_state.

@export var raycast_path: NodePath
@export var max_range := 200.0


func _init() -> void:
	phase = Phase.SENSE


func on_physics(host: Node, _delta: float) -> void:
	var target: Node2D = host.local_state.get(&"target_node", null)
	if target == null or not is_instance_valid(target):
		host.local_state[&"has_line_of_sight"] = false
		return
	if not host is Node2D:
		return

	var host2d := host as Node2D
	var ray := _get_raycast(host)

	if ray == null:
		# No raycast, use distance only
		host.local_state[&"has_line_of_sight"] = (
			host2d.global_position.distance_to(target.global_position) <= max_range
		)
		return

	var direction := (target.global_position - host2d.global_position)
	if direction.length() > max_range:
		host.local_state[&"has_line_of_sight"] = false
		return

	ray.target_position = ray.to_local(target.global_position)
	ray.force_raycast_update()

	if not ray.is_colliding():
		host.local_state[&"has_line_of_sight"] = true
	else:
		host.local_state[&"has_line_of_sight"] = (ray.get_collider() == target)


func _get_raycast(host: Node) -> RayCast2D:
	if not raycast_path.is_empty():
		var node := host.get_node_or_null(raycast_path)
		if node is RayCast2D:
			return node as RayCast2D
	for child in host.get_children():
		if child is RayCast2D and (child.name == "SightRay" or child.name == "LOSRay"):
			return child as RayCast2D
	return null
