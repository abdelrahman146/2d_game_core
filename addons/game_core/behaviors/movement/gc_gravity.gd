extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCGravity
## Applies gravity to a CharacterBody2D host.
## Writes "velocity_y" addition each physics frame.

@export var gravity_strength := 980.0
@export var max_fall_speed := 600.0


func _init() -> void:
	phase = Phase.ACT


func on_physics(host: Node, delta: float) -> void:
	if not host is CharacterBody2D:
		return
	var body := host as CharacterBody2D
	if not body.is_on_floor():
		body.velocity.y = minf(body.velocity.y + gravity_strength * delta, max_fall_speed)
