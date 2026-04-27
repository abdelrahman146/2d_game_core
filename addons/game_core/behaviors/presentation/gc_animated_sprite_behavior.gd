extends "res://addons/game_core/behaviors/presentation/gc_animation_playback_base.gd"
class_name GCAnimatedSpriteBehavior
## Drives an AnimatedSprite2D from the shared animation local_state contract.
## Reads animation_state / animation_trigger / animation_queue by default.

@export var sprite_path: NodePath

var _sprite: AnimatedSprite2D

func on_host_ready(host: Node) -> void:
	_setup_animation_contract()
	_sprite = _get_sprite(host)


func on_physics(host: Node, _delta: float) -> void:
	if _sprite == null:
		return
	_update_animation(host)


func _has_animation(anim_name: StringName) -> bool:
	return _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim_name)


func _get_current_animation_name() -> StringName:
	if _sprite == null:
		return &""
	return _sprite.animation


func _is_playing() -> bool:
	return _sprite != null and _sprite.is_playing()


func _play_animation(anim_name: StringName, restart_if_same: bool) -> void:
	if _sprite == null:
		return
	if restart_if_same and _sprite.animation == anim_name:
		_sprite.stop()
	_sprite.play(anim_name)


func _set_speed_scale(speed_scale: float) -> void:
	if _sprite != null:
		_sprite.speed_scale = speed_scale


func _get_sprite(host: Node) -> AnimatedSprite2D:
	if not sprite_path.is_empty():
		var node := host.get_node_or_null(sprite_path)
		if node is AnimatedSprite2D:
			return node as AnimatedSprite2D
	for child in host.get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
	return null
