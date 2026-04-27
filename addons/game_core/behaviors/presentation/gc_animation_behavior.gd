extends "res://addons/game_core/behaviors/presentation/gc_animation_playback_base.gd"
class_name GCAnimationBehavior
## Drives an AnimationPlayer from the shared animation local_state contract.
## Reads animation_state / animation_trigger / animation_queue by default.

@export var animator_path: NodePath

var _animator: AnimationPlayer

func on_host_ready(host: Node) -> void:
	_setup_animation_contract()
	_animator = _get_animator(host)


func on_physics(host: Node, _delta: float) -> void:
	if _animator == null:
		return
	_update_animation(host)


func _has_animation(anim_name: StringName) -> bool:
	return _animator != null and _animator.has_animation(anim_name)


func _get_current_animation_name() -> StringName:
	if _animator == null:
		return &""
	return _animator.current_animation


func _is_playing() -> bool:
	return _animator != null and _animator.is_playing()


func _play_animation(anim_name: StringName, restart_if_same: bool) -> void:
	if _animator == null:
		return
	if restart_if_same and _animator.current_animation == anim_name:
		_animator.stop()
	_animator.play(anim_name)


func _set_speed_scale(speed_scale: float) -> void:
	if _animator != null:
		_animator.speed_scale = speed_scale


func _get_animator(host: Node) -> AnimationPlayer:
	if not animator_path.is_empty():
		var node := host.get_node_or_null(animator_path)
		if node is AnimationPlayer:
			return node as AnimationPlayer
	for child in host.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
	return null
