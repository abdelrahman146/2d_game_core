extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCShoot
## Spawns a projectile scene on a cooldown.
## Fires in the facing direction or toward a target.

signal shot_fired(projectile: Node)

@export var projectile_scene: PackedScene
@export var cooldown := 1.0
@export var shoot_offset := Vector2(16, 0)
@export var projectile_speed := 200.0
@export var auto_fire := true  ## If true, fires on cooldown when target detected
@export var spawn_point_path: NodePath

var _timer := 0.0


func _init() -> void:
	phase = Phase.ACT


func on_physics(host: Node, delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	if not auto_fire:
		return
	if not host.local_state.get(&"target_detected", false):
		return
	fire(host)


func fire(host: Node) -> void:
	if projectile_scene == null or _timer > 0.0:
		return
	if not host is Node2D:
		return
	_timer = cooldown
	var host2d := host as Node2D
	var projectile := projectile_scene.instantiate()
	var spawn_pos := _get_spawn_position(host)
	var direction := _get_fire_direction(host)

	if projectile is Node2D:
		(projectile as Node2D).global_position = spawn_pos
		(projectile as Node2D).rotation = direction.angle()

	host2d.get_tree().current_scene.add_child(projectile)

	# Set velocity if projectile has it
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(direction * projectile_speed)
	elif &"velocity" in projectile:
		projectile.velocity = direction * projectile_speed
	elif projectile is CharacterBody2D:
		(projectile as CharacterBody2D).velocity = direction * projectile_speed

	shot_fired.emit(projectile)


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
