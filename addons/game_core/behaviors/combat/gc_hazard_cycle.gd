extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCHazardCycle
## Drives a reusable timed hazard window and toggles its collision.
## Writes hazard_state / hazard_active and optional animation state keys.

enum CyclePhase { IDLE, WINDUP, ACTIVE, COOLDOWN }

signal hazard_windup_started
signal hazard_activated
signal hazard_deactivated
signal cycle_finished

@export var auto_start := true
@export var loop := true
@export var start_active := false
@export var initial_delay := 0.0
@export var windup_time := 0.25
@export var active_time := 1.0
@export var cooldown_time := 0.5
@export var gate_state_key: StringName = &""
@export var gate_state_value := true
@export var state_key: StringName = &"hazard_state"
@export var active_key: StringName = &"hazard_active"
@export var animation_state_key: StringName = &"animation_state"
@export var write_animation_state := true
@export var idle_animation: StringName = &"idle"
@export var windup_animation: StringName = &"windup"
@export var active_animation: StringName = &"active"
@export var cooldown_animation: StringName = &"cooldown"
@export var visual_root_path: NodePath
@export var collision_path: NodePath
@export var toggle_visual := false

var _phase_state: CyclePhase = CyclePhase.IDLE
var _timer := 0.0
var _visual_root: Node
var _collision_root: Node


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	_visual_root = _resolve_node(host, visual_root_path)
	_collision_root = _resolve_collision_root(host)
	if start_active:
		_enter_active(host)
	else:
		_enter_idle(host, initial_delay)


func on_physics(host: Node, delta: float) -> void:
	match _phase_state:
		CyclePhase.IDLE:
			_timer = maxf(_timer - delta, 0.0)
			if auto_start and _timer <= 0.0 and _passes_gate(host):
				start_cycle(host)
		CyclePhase.WINDUP:
			_timer = maxf(_timer - delta, 0.0)
			if _timer <= 0.0:
				_enter_active(host)
		CyclePhase.ACTIVE:
			if active_time < 0.0:
				return
			_timer = maxf(_timer - delta, 0.0)
			if _timer <= 0.0:
				_enter_cooldown(host)
		CyclePhase.COOLDOWN:
			_timer = maxf(_timer - delta, 0.0)
			if _timer <= 0.0:
				cycle_finished.emit()
				if loop and auto_start and _passes_gate(host):
					start_cycle(host)
				else:
					_enter_idle(host, 0.0)


func start_cycle(host: Node) -> void:
	if _phase_state == CyclePhase.WINDUP or _phase_state == CyclePhase.ACTIVE:
		return
	_enter_windup(host)


func stop_cycle(host: Node) -> void:
	_enter_idle(host, 0.0)


func get_phase_name() -> StringName:
	match _phase_state:
		CyclePhase.WINDUP:
			return &"windup"
		CyclePhase.ACTIVE:
			return &"active"
		CyclePhase.COOLDOWN:
			return &"cooldown"
	return &"idle"


func _enter_idle(host: Node, delay: float) -> void:
	_phase_state = CyclePhase.IDLE
	_timer = maxf(delay, 0.0)
	_write_state(host, &"idle", false, idle_animation)
	_set_visual_visible(not toggle_visual)
	_set_collision_enabled(false)


func _enter_windup(host: Node) -> void:
	_phase_state = CyclePhase.WINDUP
	_timer = maxf(windup_time, 0.0)
	_write_state(host, &"windup", false, windup_animation)
	_set_visual_visible(not toggle_visual)
	_set_collision_enabled(false)
	hazard_windup_started.emit()
	if _timer <= 0.0:
		_enter_active(host)


func _enter_active(host: Node) -> void:
	_phase_state = CyclePhase.ACTIVE
	_timer = active_time
	_write_state(host, &"active", true, active_animation)
	_set_visual_visible(true)
	_set_collision_enabled(true)
	hazard_activated.emit()
	if _timer == 0.0:
		_enter_cooldown(host)


func _enter_cooldown(host: Node) -> void:
	_phase_state = CyclePhase.COOLDOWN
	_timer = maxf(cooldown_time, 0.0)
	_write_state(host, &"cooldown", false, cooldown_animation)
	_set_visual_visible(not toggle_visual)
	_set_collision_enabled(false)
	hazard_deactivated.emit()
	if _timer <= 0.0:
		cycle_finished.emit()
		if loop and auto_start and _passes_gate(host):
			start_cycle(host)
		else:
			_enter_idle(host, 0.0)


func _write_state(host: Node, state: StringName, active: bool, animation: StringName) -> void:
	host.local_state[state_key] = state
	host.local_state[active_key] = active
	if write_animation_state and not animation_state_key.is_empty() and not animation.is_empty():
		host.local_state[animation_state_key] = animation


func _passes_gate(host: Node) -> bool:
	if gate_state_key.is_empty():
		return true
	if not host.local_state.has(gate_state_key):
		return false
	return host.local_state[gate_state_key] == gate_state_value


func _resolve_node(host: Node, path: NodePath) -> Node:
	if path.is_empty():
		return null
	return host.get_node_or_null(path)


func _resolve_collision_root(host: Node) -> Node:
	var resolved := _resolve_node(host, collision_path)
	if resolved != null:
		return resolved
	for child in host.get_children():
		if child is Area2D and (child.name == "DamageArea" or child.name == "HitArea" or child.name == "Hitbox"):
			return child
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return child
	return null


func _set_visual_visible(visible: bool) -> void:
	if _visual_root is CanvasItem:
		(_visual_root as CanvasItem).visible = visible


func _set_collision_enabled(enabled: bool) -> void:
	if _collision_root == null:
		return
	_set_collision_node_enabled(_collision_root, enabled)


func _set_collision_node_enabled(node: Node, enabled: bool) -> void:
	if node is Area2D:
		(node as Area2D).monitoring = enabled
		(node as Area2D).monitorable = enabled
	elif node is CollisionShape2D:
		(node as CollisionShape2D).disabled = not enabled
	elif node is CollisionPolygon2D:
		(node as CollisionPolygon2D).disabled = not enabled

	for child in node.get_children():
		_set_collision_node_enabled(child, enabled)
