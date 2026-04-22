extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCDrop
## Drops/spawns an object (bomb, item, etc.) when a condition is met.
## Condition: target detected, timer, or manual trigger.

enum TriggerMode { TARGET_DETECTED, TIMER }

signal dropped(instance: Node)

@export var drop_scene: PackedScene
@export var cooldown := 2.0
@export var drop_offset := Vector2(0, 16)
@export var auto_drop := true  ## If true, auto drop uses trigger_mode.
@export var drop_on_timer := false  ## Legacy compatibility for existing timer-based scenes.
@export var trigger_mode: TriggerMode = TriggerMode.TARGET_DETECTED
@export var timer_interval := 3.0
## If set, auto drop only happens when host.local_state[gate_state_key] matches gate_state_value.
@export var gate_state_key: StringName = &""
@export var gate_state_value := true

var _timer := 0.0


func _init() -> void:
	phase = Phase.ACT


func on_physics(host: Node, delta: float) -> void:
	_timer = maxf(_timer - delta, 0.0)
	if _timer > 0.0:
		return
	if not _auto_drop_enabled():
		return
	if not _passes_gate(host):
		return
	if not _can_auto_drop(host):
		return
	drop(host)


func drop(host: Node) -> void:
	if drop_scene == null or _timer > 0.0:
		return
	if not host is Node2D:
		return
	var host2d := host as Node2D
	var spawn_parent := _get_spawn_parent(host2d)
	if spawn_parent == null:
		return
	var instance := drop_scene.instantiate()
	if instance is Node2D:
		(instance as Node2D).global_position = host2d.global_position + drop_offset
	spawn_parent.add_child(instance)
	_timer = _get_retrigger_delay()
	dropped.emit(instance)


func _auto_drop_enabled() -> bool:
	return auto_drop or drop_on_timer


func _can_auto_drop(host: Node) -> bool:
	if _uses_timer_mode():
		return true
	return host.local_state.get(&"target_detected", false)


func _uses_timer_mode() -> bool:
	return drop_on_timer or trigger_mode == TriggerMode.TIMER


func _get_retrigger_delay() -> float:
	if _uses_timer_mode():
		return maxf(timer_interval, 0.0)
	return maxf(cooldown, 0.0)


func _passes_gate(host: Node) -> bool:
	if gate_state_key.is_empty():
		return true
	if not host.local_state.has(gate_state_key):
		return false
	return host.local_state[gate_state_key] == gate_state_value


func _get_spawn_parent(host: Node2D) -> Node:
	var tree := host.get_tree()
	if tree == null:
		return null
	if tree.current_scene != null and is_instance_valid(tree.current_scene):
		return tree.current_scene
	if host.get_parent() != null:
		return host.get_parent()
	return tree.root
