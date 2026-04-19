extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCFollowTarget
## Moves toward a target position or node. Writes "move_direction" to local_state.
## Reads target from local_state["target_position"] or local_state["target_node"].

@export var speed := 80.0
@export var stop_distance := 8.0


func _init() -> void:
	phase = Phase.DECIDE


func on_physics(host: Node, _delta: float) -> void:
	if not host is Node2D:
		return
	var host2d := host as Node2D
	var target_pos := _get_target_position(host)
	if target_pos == Vector2.INF:
		host.local_state[&"move_direction"] = Vector2.ZERO
		return
	var diff := target_pos - host2d.global_position
	if diff.length() <= stop_distance:
		host.local_state[&"move_direction"] = Vector2.ZERO
		return
	host.local_state[&"move_direction"] = diff.normalized()
	host.local_state[&"speed"] = speed


func _get_target_position(host: Node) -> Vector2:
	var target_node: Node2D = host.local_state.get(&"target_node", null)
	if target_node and is_instance_valid(target_node):
		return target_node.global_position
	var pos: Variant = host.local_state.get(&"target_position", null)
	if pos is Vector2:
		return pos
	return Vector2.INF
