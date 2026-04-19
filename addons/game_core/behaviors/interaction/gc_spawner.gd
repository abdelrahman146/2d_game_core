extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCSpawner
## Spawns entities from a scene on a timer, signal, or condition.

const _Health = preload("res://addons/game_core/behaviors/combat/gc_health.gd")

signal spawned(instance: Node)

@export var spawn_scene: PackedScene
@export var spawn_on_death := true  ## Spawn when host dies
@export var spawn_on_timer := false
@export var timer_interval := 5.0
@export var spawn_offset := Vector2.ZERO
@export var max_spawns := -1  ## -1 for unlimited

var _timer := 0.0
var _spawn_count := 0


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	if spawn_on_death:
		for child in host.get_children():
			if child is _Health:
				(child as _Health).died.connect(_on_host_died.bind(host))
				break


func on_physics(host: Node, delta: float) -> void:
	if not spawn_on_timer:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = timer_interval
		spawn(host)


func spawn(host: Node) -> void:
	if spawn_scene == null:
		return
	if max_spawns >= 0 and _spawn_count >= max_spawns:
		return
	if not host is Node2D:
		return
	var instance := spawn_scene.instantiate()
	if instance is Node2D:
		(instance as Node2D).global_position = (host as Node2D).global_position + spawn_offset
	(host as Node2D).get_tree().current_scene.add_child(instance)
	_spawn_count += 1
	spawned.emit(instance)


func _on_host_died(host: Node) -> void:
	spawn(host)
