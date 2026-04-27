extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCDestroyOnHit
## Destroys the host when health reaches 0 or on a signal.

const _Health = preload("res://addons/game_core/behaviors/combat/gc_health.gd")

@export var destroy_delay := 0.0  ## Seconds to wait before destroying
@export var play_animation := ""  ## Animation id to request before destroying
@export var animation_trigger_key: StringName = &"animation_trigger"


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	for child in host.get_children():
		if child is _Health:
			(child as _Health).died.connect(_on_died.bind(host))
			break


func _on_died(host: Node) -> void:
	if not play_animation.is_empty() and not animation_trigger_key.is_empty():
		host.local_state[animation_trigger_key] = StringName(play_animation)

	if destroy_delay > 0.0:
		await host.get_tree().create_timer(destroy_delay).timeout

	if is_instance_valid(host):
		host.queue_free()
