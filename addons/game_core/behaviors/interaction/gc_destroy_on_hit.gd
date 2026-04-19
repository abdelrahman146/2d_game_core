extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCDestroyOnHit
## Destroys the host when health reaches 0 or on a signal.

const _Health = preload("res://addons/game_core/behaviors/combat/gc_health.gd")

@export var destroy_delay := 0.0  ## Seconds to wait before destroying
@export var play_animation := ""  ## Animation to play before destroying


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	for child in host.get_children():
		if child is _Health:
			(child as _Health).died.connect(_on_died.bind(host))
			break


func _on_died(host: Node) -> void:
	if not play_animation.is_empty():
		var anim_player: AnimationPlayer = host.find_child("AnimationPlayer")
		if anim_player:
			anim_player.play(play_animation)

	if destroy_delay > 0.0:
		await host.get_tree().create_timer(destroy_delay).timeout

	if is_instance_valid(host):
		host.queue_free()
