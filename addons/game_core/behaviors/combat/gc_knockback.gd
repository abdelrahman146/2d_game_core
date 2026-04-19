extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCKnockback
## Applies knockback to the host when hit.
## Reads "just_hit" from local_state, applies force away from damage source.

const _Health = preload("res://addons/game_core/behaviors/combat/gc_health.gd")

@export var knockback_force := 200.0
@export var decay_speed := 400.0

var _knockback_velocity := Vector2.ZERO


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	# Connect to health behavior's damaged signal if available
	for child in host.get_children():
		if child is _Health:
			(child as _Health).damaged.connect(_on_damaged.bind(host))
			break


func on_physics(host: Node, delta: float) -> void:
	if _knockback_velocity.length() < 1.0:
		_knockback_velocity = Vector2.ZERO
		return
	if host is CharacterBody2D:
		(host as CharacterBody2D).velocity += _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, decay_speed * delta)


func _on_damaged(_amount: int, source: Node, host: Node) -> void:
	if source == null or not source is Node2D or not host is Node2D:
		return
	var direction := ((host as Node2D).global_position - (source as Node2D).global_position).normalized()
	_knockback_velocity = direction * knockback_force
