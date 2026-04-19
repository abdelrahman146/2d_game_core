extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCDrop
## Drops/spawns an object (bomb, item, etc.) when a condition is met.
## Condition: target detected, timer, or manual trigger.

signal dropped(instance: Node)

@export var drop_scene: PackedScene
@export var cooldown := 2.0
@export var drop_offset := Vector2(0, 16)
@export var auto_drop := true  ## Drop automatically when target detected
@export var drop_on_timer := false
@export var timer_interval := 3.0

var _timer := 0.0


func _init() -> void:
	phase = Phase.ACT


func on_physics(host: Node, delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return

	if drop_on_timer:
		drop(host)
		return

	if auto_drop and host.local_state.get(&"target_detected", false):
		drop(host)


func drop(host: Node) -> void:
	if drop_scene == null or _timer > 0.0:
		return
	if not host is Node2D:
		return
	_timer = cooldown
	var host2d := host as Node2D
	var instance := drop_scene.instantiate()
	if instance is Node2D:
		(instance as Node2D).global_position = host2d.global_position + drop_offset
	host2d.get_tree().current_scene.add_child(instance)
	dropped.emit(instance)
