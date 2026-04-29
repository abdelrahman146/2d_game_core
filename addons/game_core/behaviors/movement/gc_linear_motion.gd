extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCLinearMotion
## Moves any Node2D host by a constant velocity, with optional cleanup.

signal lifetime_finished
signal screen_exited

@export var velocity := Vector2.ZERO
@export var use_local_space := false
@export var velocity_state_key: StringName = &""
@export var active_state_key: StringName = &""
@export var active_state_value := true
@export var lifetime := -1.0
@export var free_on_lifetime_end := true
@export var free_on_screen_exit := false
@export var screen_notifier_path: NodePath

var _remaining_lifetime := -1.0
var _lifetime_finished := false
var _screen_notifier: VisibleOnScreenNotifier2D


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	_remaining_lifetime = lifetime
	_lifetime_finished = false
	_screen_notifier = _resolve_screen_notifier(host)
	if _screen_notifier != null and free_on_screen_exit:
		_screen_notifier.screen_exited.connect(_on_screen_exited.bind(host))


func on_physics(host: Node, delta: float) -> void:
	if not host is Node2D:
		return
	if not _passes_active_gate(host):
		return

	var host2d := host as Node2D
	var step_velocity := _get_velocity(host)
	if use_local_space:
		step_velocity = step_velocity.rotated(host2d.global_rotation)
	host2d.global_position += step_velocity * delta

	if lifetime >= 0.0 and not _lifetime_finished:
		_remaining_lifetime = maxf(_remaining_lifetime - delta, 0.0)
		if _remaining_lifetime <= 0.0:
			_lifetime_finished = true
			lifetime_finished.emit()
			if free_on_lifetime_end and is_instance_valid(host):
				host.queue_free()


func reset_lifetime() -> void:
	_remaining_lifetime = lifetime
	_lifetime_finished = false


func _get_velocity(host: Node) -> Vector2:
	if not velocity_state_key.is_empty() and host.local_state.has(velocity_state_key):
		var state_velocity: Variant = host.local_state[velocity_state_key]
		if state_velocity is Vector2:
			return state_velocity
	return velocity


func _passes_active_gate(host: Node) -> bool:
	if active_state_key.is_empty():
		return true
	if not host.local_state.has(active_state_key):
		return false
	return host.local_state[active_state_key] == active_state_value


func _resolve_screen_notifier(host: Node) -> VisibleOnScreenNotifier2D:
	if not screen_notifier_path.is_empty():
		var node := host.get_node_or_null(screen_notifier_path)
		if node is VisibleOnScreenNotifier2D:
			return node as VisibleOnScreenNotifier2D
	for child in host.get_children():
		if child is VisibleOnScreenNotifier2D:
			return child as VisibleOnScreenNotifier2D
	return null


func _on_screen_exited(host: Node) -> void:
	screen_exited.emit()
	if is_instance_valid(host):
		host.queue_free()
