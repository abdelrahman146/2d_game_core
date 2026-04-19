extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCHealth
## Tracks health. Emits signals on damage and death.
## Writes "health", "max_health", "is_alive" to local_state.

signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health := 3
@export var invincibility_time := 0.0

var _invincible_timer := 0.0


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	host.local_state[&"health"] = max_health
	host.local_state[&"max_health"] = max_health
	host.local_state[&"is_alive"] = true


func on_physics(host: Node, delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
	host.local_state[&"invincible"] = _invincible_timer > 0.0


func take_damage(host: Node, amount: int, source: Node = null) -> void:
	if not host.local_state.get(&"is_alive", true):
		return
	if _invincible_timer > 0.0:
		return
	var health: int = host.local_state.get(&"health", 0) - amount
	health = maxi(health, 0)
	host.local_state[&"health"] = health
	host.local_state[&"just_hit"] = true

	if invincibility_time > 0.0:
		_invincible_timer = invincibility_time

	damaged.emit(amount, source)

	if health <= 0:
		host.local_state[&"is_alive"] = false
		died.emit()


func heal(host: Node, amount: int) -> void:
	var max_hp: int = host.local_state.get(&"max_health", max_health)
	var health: int = mini(host.local_state.get(&"health", 0) + amount, max_hp)
	host.local_state[&"health"] = health
	healed.emit(amount)
