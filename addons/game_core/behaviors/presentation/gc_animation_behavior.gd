extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCAnimationBehavior
## Plays animations based on local_state changes.
## Maps state values to animation names.

@export var animator_path: NodePath
@export var idle_animation := "idle"
@export var move_animation := "walk"
@export var death_animation := "death"
@export var hit_animation := "hit"

var _animator: AnimationPlayer


func _init() -> void:
	phase = Phase.PRESENT


func on_host_ready(host: Node) -> void:
	_animator = _get_animator(host)


func on_physics(host: Node, _delta: float) -> void:
	if _animator == null:
		return

	if not host.local_state.get(&"is_alive", true):
		_play(death_animation)
		return

	if host.local_state.get(&"just_hit", false):
		host.local_state[&"just_hit"] = false
		_play(hit_animation)
		return

	var move_dir: Vector2 = host.local_state.get(&"move_direction", Vector2.ZERO)
	if move_dir.length() > 0.01:
		_play(move_animation)
	else:
		_play(idle_animation)


func _play(anim_name: String) -> void:
	if anim_name.is_empty():
		return
	if _animator.has_animation(anim_name) and _animator.current_animation != anim_name:
		_animator.play(anim_name)


func _get_animator(host: Node) -> AnimationPlayer:
	if not animator_path.is_empty():
		var node := host.get_node_or_null(animator_path)
		if node is AnimationPlayer:
			return node as AnimationPlayer
	for child in host.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
	return null
