extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCFlashOnHit
## Flashes the sprite when the host takes damage.

const _Health = preload("res://addons/game_core/behaviors/combat/gc_health.gd")

@export var flash_color := Color.WHITE
@export var flash_duration := 0.1
@export var flash_count := 2
@export var sprite_path: NodePath

var _original_modulate := Color.WHITE


func _init() -> void:
	phase = Phase.PRESENT


func on_host_ready(host: Node) -> void:
	var sprite := _get_sprite(host)
	if sprite:
		_original_modulate = sprite.modulate
	for child in host.get_children():
		if child is _Health:
			(child as _Health).damaged.connect(_on_damaged.bind(host))
			break


func _on_damaged(_amount: int, _source: Node, host: Node) -> void:
	var sprite := _get_sprite(host)
	if sprite == null:
		return
	_do_flash(sprite)


func _do_flash(sprite: Sprite2D) -> void:
	var tween := sprite.get_tree().create_tween()
	for i in range(flash_count):
		tween.tween_property(sprite, "modulate", flash_color, flash_duration * 0.5)
		tween.tween_property(sprite, "modulate", _original_modulate, flash_duration * 0.5)


func _get_sprite(host: Node) -> Sprite2D:
	if not sprite_path.is_empty():
		var node := host.get_node_or_null(sprite_path)
		if node is Sprite2D:
			return node as Sprite2D
	for child in host.get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null
