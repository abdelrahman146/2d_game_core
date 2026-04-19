extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCWander
## Random movement within an area. Writes "move_direction" to local_state.

@export var speed := 40.0
@export var wander_radius := 80.0
@export var pause_time := 1.0
@export var move_time := 2.0

var _start_position := Vector2.ZERO
var _timer := 0.0
var _is_moving := true
var _current_dir := Vector2.ZERO


func _init() -> void:
	phase = Phase.DECIDE


func on_host_ready(host: Node) -> void:
	if host is Node2D:
		_start_position = (host as Node2D).global_position
	_pick_direction()


func on_physics(host: Node, delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_is_moving = not _is_moving
		if _is_moving:
			_pick_direction()
			_timer = move_time
		else:
			_timer = pause_time

	if _is_moving:
		if host is Node2D:
			var offset: float = ((host as Node2D).global_position - _start_position).length()
			if offset > wander_radius:
				_current_dir = (_start_position - (host as Node2D).global_position).normalized()
		host.local_state[&"move_direction"] = _current_dir
		host.local_state[&"speed"] = speed
	else:
		host.local_state[&"move_direction"] = Vector2.ZERO


func _pick_direction() -> void:
	var angle := randf() * TAU
	_current_dir = Vector2(cos(angle), sin(angle))
	_timer = move_time
