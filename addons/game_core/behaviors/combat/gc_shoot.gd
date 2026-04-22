extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCShoot
## Spawns a projectile scene on a cooldown.
## Fires in the facing direction or toward a target.

enum TriggerMode { TARGET_DETECTED, TIMER }

signal shot_fired(projectile: Node)

@export var projectile_scene: PackedScene
@export var cooldown := 1.0
@export var shoot_offset := Vector2(16, 0)
@export var projectile_speed := 200.0
@export var auto_fire := true  ## If true, auto fire uses trigger_mode.
@export var trigger_mode: TriggerMode = TriggerMode.TARGET_DETECTED
## If set, auto fire only happens when host.local_state[gate_state_key] matches gate_state_value.
@export var gate_state_key: StringName = &""
@export var gate_state_value := true
@export var spawn_point_path: NodePath

var _timer := 0.0


func _init() -> void:
	phase = Phase.ACT


func on_physics(host: Node, delta: float) -> void:
	_timer = maxf(_timer - delta, 0.0)
	if _timer > 0.0:
		return
	if not auto_fire:
		return
	if not _passes_gate(host):
		return
	if not _can_auto_fire(host):
		return
	fire(host)


func fire(host: Node) -> void:
	if projectile_scene == null or _timer > 0.0:
		return
	if not host is Node2D:
		return
	var host2d := host as Node2D
	var spawn_parent := _get_spawn_parent(host2d)
	if spawn_parent == null:
		return
	var projectile := projectile_scene.instantiate()
	var spawn_pos := _get_spawn_position(host)
	var direction := _get_fire_direction(host)

	if projectile is Node2D:
		(projectile as Node2D).global_position = spawn_pos
		(projectile as Node2D).rotation = direction.angle()

	spawn_parent.add_child(projectile)
	_timer = maxf(cooldown, 0.0)

	# Set velocity if projectile has it
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(direction * projectile_speed)
	elif &"velocity" in projectile:
		projectile.velocity = direction * projectile_speed
	elif projectile is CharacterBody2D:
		(projectile as CharacterBody2D).velocity = direction * projectile_speed

	shot_fired.emit(projectile)


func _can_auto_fire(host: Node) -> bool:
	match trigger_mode:
		TriggerMode.TIMER:
			return true
		TriggerMode.TARGET_DETECTED:
			return host.local_state.get(&"target_detected", false)
	return false


func _passes_gate(host: Node) -> bool:
	if gate_state_key.is_empty():
		return true
	if not host.local_state.has(gate_state_key):
		return false
	return host.local_state[gate_state_key] == gate_state_value


func _get_spawn_position(host: Node) -> Vector2:
	if not spawn_point_path.is_empty():
		var point := host.get_node_or_null(spawn_point_path)
		if point is Node2D:
			return (point as Node2D).global_position
	var facing: int = host.local_state.get(&"facing_direction", 1)
	return (host as Node2D).global_position + Vector2(shoot_offset.x * facing, shoot_offset.y)


func _get_fire_direction(host: Node) -> Vector2:
	var target: Node2D = host.local_state.get(&"target_node", null)
	if target and is_instance_valid(target):
		return ((target.global_position) - (host as Node2D).global_position).normalized()
	var facing: int = host.local_state.get(&"facing_direction", 1)
	return Vector2.RIGHT * facing


func _get_spawn_parent(host: Node2D) -> Node:
	var tree := host.get_tree()
	if tree == null:
		return null
	if tree.current_scene != null and is_instance_valid(tree.current_scene):
		return tree.current_scene
	if host.get_parent() != null:
		return host.get_parent()
	return tree.root
