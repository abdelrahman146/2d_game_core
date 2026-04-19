extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCSimpleMovement
## Reads "move_direction" and "speed" from local_state and applies velocity.
## Then calls move_and_slide on CharacterBody2D hosts.

@export var default_speed := 60.0


func _init() -> void:
	phase = Phase.ACT


func on_physics(host: Node, _delta: float) -> void:
	if not host is CharacterBody2D:
		return
	var body := host as CharacterBody2D
	var dir: Vector2 = host.local_state.get(&"move_direction", Vector2.ZERO)
	var speed: float = host.local_state.get(&"speed", default_speed)
	body.velocity.x = dir.x * speed
	if host.local_state.get(&"no_gravity", false):
		body.velocity.y = dir.y * speed
	body.move_and_slide()
