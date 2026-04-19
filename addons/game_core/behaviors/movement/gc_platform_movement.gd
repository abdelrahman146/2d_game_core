extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCPlatformMovement
## Moves a StaticBody2D (or AnimatableBody2D) along a path.
## Useful for moving platforms, elevators, conveyor belts.

@export var points: PackedVector2Array = []
@export var speed := 50.0
@export var pause_at_points := 0.5
@export var loop := true

var _current_index := 0
var _moving := true
var _pause_timer := 0.0
var _origin := Vector2.ZERO


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	if host is Node2D:
		_origin = (host as Node2D).global_position


func on_physics(host: Node, delta: float) -> void:
	if not host is Node2D or points.is_empty():
		return
	var host2d := host as Node2D

	if not _moving:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_moving = true
			_advance_index()
		return

	var target := _origin + points[_current_index]
	var diff := target - host2d.global_position
	if diff.length() <= speed * delta:
		host2d.global_position = target
		_moving = false
		_pause_timer = pause_at_points
	else:
		host2d.global_position += diff.normalized() * speed * delta


func _advance_index() -> void:
	_current_index += 1
	if _current_index >= points.size():
		if loop:
			_current_index = 0
		else:
			_current_index = points.size() - 1
			_moving = false
