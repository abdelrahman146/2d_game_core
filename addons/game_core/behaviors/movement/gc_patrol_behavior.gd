extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCPatrolBehavior
## Patrols back and forth. Writes "move_direction" and "speed" to local_state.
## Reverses on edge detection, wall detection, or range limits.

enum PatrolMode { RANGE, EDGE_DETECT, WALL_DETECT }

@export var patrol_mode: PatrolMode = PatrolMode.RANGE
@export var axis: Vector2 = Vector2.RIGHT  ## Patrol axis (RIGHT for x, DOWN for y)
@export var speed := 60.0
@export var patrol_distance := 100.0  ## Distance from start in each direction (RANGE mode)
@export var start_direction := 1  ## 1 or -1

var _direction := 1
var _start_position := Vector2.ZERO
var _started := false


func _init() -> void:
	phase = Phase.DECIDE


func on_host_ready(host: Node) -> void:
	_direction = 1 if start_direction >= 0 else -1
	if host is Node2D:
		_start_position = (host as Node2D).global_position
	_started = true


func on_physics(host: Node, _delta: float) -> void:
	if not _started:
		return

	if _should_reverse(host):
		_direction *= -1

	host.local_state[&"move_direction"] = axis * _direction
	host.local_state[&"speed"] = speed
	host.local_state[&"facing_direction"] = _direction


func _should_reverse(host: Node) -> bool:
	match patrol_mode:
		PatrolMode.RANGE:
			return _range_exceeded(host)
		PatrolMode.EDGE_DETECT:
			return host.local_state.get(&"edge_ahead", false) or host.local_state.get(&"wall_ahead", false)
		PatrolMode.WALL_DETECT:
			return host.local_state.get(&"wall_ahead", false)
	return false


func _range_exceeded(host: Node) -> bool:
	if not host is Node2D:
		return false
	var pos: Vector2 = (host as Node2D).global_position
	var offset: float = (pos - _start_position).dot(axis)
	return (
		(_direction > 0 and offset >= patrol_distance)
		or (_direction < 0 and offset <= -patrol_distance)
	)
