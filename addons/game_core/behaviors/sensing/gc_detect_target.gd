extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCDetectTarget
## Detects a target (e.g., player) via Area2D overlap or distance.
## Writes "target_node" and "target_detected" to local_state.

@export var detection_area_path: NodePath
@export var detect_group: StringName = &"player"
@export var detection_radius := 150.0
@export var use_area := true  ## If false, uses distance check instead

var _area: Area2D


func _init() -> void:
	phase = Phase.SENSE


func on_host_ready(host: Node) -> void:
	if use_area:
		_area = _get_area(host)
		if _area:
			_area.body_entered.connect(_on_body_entered.bind(host))
			_area.body_exited.connect(_on_body_exited.bind(host))


func on_physics(host: Node, _delta: float) -> void:
	if use_area:
		return  # Area handles it via signals
	# Distance-based detection
	if not host is Node2D:
		return
	var host2d := host as Node2D
	var target := _find_nearest_in_group(host2d)
	if target and host2d.global_position.distance_to(target.global_position) <= detection_radius:
		host.local_state[&"target_node"] = target
		host.local_state[&"target_detected"] = true
	else:
		host.local_state[&"target_node"] = null
		host.local_state[&"target_detected"] = false


func _on_body_entered(body: Node2D, host: Node) -> void:
	if body.is_in_group(detect_group):
		host.local_state[&"target_node"] = body
		host.local_state[&"target_detected"] = true


func _on_body_exited(body: Node2D, host: Node) -> void:
	if body.is_in_group(detect_group):
		if host.local_state.get(&"target_node") == body:
			host.local_state[&"target_node"] = null
			host.local_state[&"target_detected"] = false


func _get_area(host: Node) -> Area2D:
	if not detection_area_path.is_empty():
		var node := host.get_node_or_null(detection_area_path)
		if node is Area2D:
			return node as Area2D
	for child in host.get_children():
		if child is Area2D and (child.name == "DetectionArea" or child.name == "DetectArea"):
			return child as Area2D
	return null


func _find_nearest_in_group(from: Node2D) -> Node2D:
	var nodes := from.get_tree().get_nodes_in_group(detect_group)
	var nearest: Node2D = null
	var nearest_dist := INF
	for node in nodes:
		if node is Node2D:
			var dist := from.global_position.distance_to((node as Node2D).global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = node as Node2D
	return nearest
