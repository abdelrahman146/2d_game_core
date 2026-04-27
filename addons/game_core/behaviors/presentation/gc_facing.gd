extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCFacing
## Flips the host's sprite or entire node based on facing_direction in local_state.

@export var flip_sprite := true  ## Flip Sprite2D/AnimatedSprite2D.flip_h
@export var flip_scale := false  ## Flip via scale.x (for complex nodes)
@export var sprite_path: NodePath


func _init() -> void:
	phase = Phase.PRESENT


func on_physics(host: Node, _delta: float) -> void:
	var facing: int = host.local_state.get(&"facing_direction", 1)
	if facing == 0:
		return

	if flip_sprite:
		var visual: Node = _get_visual(host)
		if visual:
			visual.set("flip_h", facing < 0)

	if flip_scale and host is Node2D:
		var s := (host as Node2D).scale
		s.x = abs(s.x) * facing
		(host as Node2D).scale = s


func _get_visual(host: Node) -> Node:
	if not sprite_path.is_empty():
		var node := host.get_node_or_null(sprite_path)
		if _supports_flip(node):
			return node
	for child in host.get_children():
		if _supports_flip(child):
			return child
	return null


func _supports_flip(node: Node) -> bool:
	return node is Sprite2D or node is AnimatedSprite2D
