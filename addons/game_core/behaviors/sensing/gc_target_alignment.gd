extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCTargetAlignment
## Writes a boolean gate when a target sits within a configurable axis tolerance.
## Useful for lane-based shooters and band-based traps.

enum Axis { X, Y }

@export var target_key: StringName = &"target_node"
@export var aligned_key: StringName = &"target_aligned"
@export var delta_key: StringName = &"target_alignment_delta"
@export var axis: Axis = Axis.X
@export var tolerance := 16.0


func _init() -> void:
	phase = Phase.SENSE


func on_host_ready(host: Node) -> void:
	host.local_state[aligned_key] = false
	host.local_state[delta_key] = 0.0


func on_physics(host: Node, _delta: float) -> void:
	if not host is Node2D:
		_set_result(host, false, 0.0)
		return

	var target: Variant = host.local_state.get(target_key, null)
	if not (target is Node2D) or not is_instance_valid(target):
		_set_result(host, false, 0.0)
		return

	var delta := (target as Node2D).global_position - (host as Node2D).global_position
	var axis_delta := delta.x if axis == Axis.X else delta.y
	_set_result(host, absf(axis_delta) <= tolerance, axis_delta)


func _set_result(host: Node, aligned: bool, axis_delta: float) -> void:
	host.local_state[aligned_key] = aligned
	host.local_state[delta_key] = axis_delta