extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCVisibilityCull
## Disables work on the host while it is off-screen.
##
## Wraps a VisibleOnScreenEnabler2D (Godot 4's replacement for
## VisibilityNotifier2D) and lets you opt in to which kinds of work get
## paused when the host leaves the screen rect.
##
## Add as a child of any actor host. By default it looks for an existing
## VisibleOnScreenEnabler2D child; if none is found one is created and its
## rect is sized from `cull_rect`.
##
## This is purely a performance optimization. Behaviors that must keep
## running off-screen (e.g., spawn timers, far-side patrols) should not be
## affected; in that case keep `pause_behaviors = false` and pause only
## animation / collision.

@export var enabler_path: NodePath
## Rect (in the host's local space) used when auto-creating the enabler.
@export var cull_rect := Rect2(-32, -32, 64, 64)
## When off-screen, set the host's `process_mode` so behavior dispatch stops.
@export var pause_behaviors := true
## When off-screen, disable the host's first AnimationPlayer / AnimatedSprite2D.
@export var pause_animation := true
## When off-screen, deferred-disable child CollisionShape2D / CollisionPolygon2D.
@export var pause_collision := false

var _enabler: VisibleOnScreenEnabler2D
var _on_screen := true


func _init() -> void:
	phase = Phase.PRESENT


func on_host_ready(host: Node) -> void:
	_enabler = _resolve_enabler(host)
	if _enabler == null:
		return
	_enabler.screen_entered.connect(_on_screen_entered.bind(host))
	_enabler.screen_exited.connect(_on_screen_exited.bind(host))


func on_host_destroyed(_host: Node) -> void:
	_enabler = null


func _on_screen_entered(host: Node) -> void:
	_on_screen = true
	_apply(host, true)


func _on_screen_exited(host: Node) -> void:
	_on_screen = false
	_apply(host, false)


func _apply(host: Node, on_screen: bool) -> void:
	if pause_behaviors and host is Node:
		host.process_mode = (
			Node.PROCESS_MODE_INHERIT if on_screen else Node.PROCESS_MODE_DISABLED
		)
	if pause_animation:
		_set_animation_active(host, on_screen)
	if pause_collision:
		_set_collision_active(host, on_screen)


func _set_animation_active(host: Node, active: bool) -> void:
	for child in host.get_children():
		if child is AnimationPlayer:
			(child as AnimationPlayer).active = active
		elif child is AnimatedSprite2D:
			var sprite := child as AnimatedSprite2D
			if active:
				sprite.play()
			else:
				sprite.pause()


func _set_collision_active(host: Node, active: bool) -> void:
	for child in host.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred(&"disabled", not active)


func _resolve_enabler(host: Node) -> VisibleOnScreenEnabler2D:
	if not enabler_path.is_empty():
		var node := host.get_node_or_null(enabler_path)
		if node is VisibleOnScreenEnabler2D:
			return node as VisibleOnScreenEnabler2D
	for child in host.get_children():
		if child is VisibleOnScreenEnabler2D:
			return child as VisibleOnScreenEnabler2D
	# Auto-create one sized from cull_rect.
	if not (host is Node2D):
		return null
	var enabler := VisibleOnScreenEnabler2D.new()
	enabler.name = &"VisibleOnScreenEnabler2D"
	enabler.rect = cull_rect
	enabler.enable_mode = VisibleOnScreenEnabler2D.ENABLE_MODE_INHERIT
	host.add_child(enabler)
	return enabler
