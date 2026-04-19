extends "res://addons/game_core/screens/transitions/gc_transition.gd"
class_name GCSlideTransition
## Slides the old screen out and new screen in from a direction.

enum Direction { LEFT, RIGHT, UP, DOWN }

@export var direction: Direction = Direction.LEFT
@export var duration: float = 0.3


func play_exit(canvas: CanvasLayer) -> void:
	var rect := _get_or_create_rect(canvas)
	rect.color = Color.BLACK
	rect.modulate.a = 0.0
	rect.visible = true
	rect.position = Vector2.ZERO
	var target := _get_offset(canvas)
	var tween := canvas.get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration * 0.5)
	tween.tween_callback(func(): finished.emit())


func play_enter(canvas: CanvasLayer) -> void:
	var rect := _get_or_create_rect(canvas)
	rect.color = Color.BLACK
	rect.modulate.a = 1.0
	rect.visible = true
	var tween := canvas.get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration * 0.5)
	tween.tween_callback(func():
		rect.visible = false
		finished.emit()
	)


func _get_offset(canvas: CanvasLayer) -> Vector2:
	var size := canvas.get_viewport().get_visible_rect().size
	match direction:
		Direction.LEFT: return Vector2(-size.x, 0)
		Direction.RIGHT: return Vector2(size.x, 0)
		Direction.UP: return Vector2(0, -size.y)
		Direction.DOWN: return Vector2(0, size.y)
	return Vector2.ZERO


func _get_or_create_rect(canvas: CanvasLayer) -> ColorRect:
	var existing := canvas.get_node_or_null("TransitionRect")
	if existing is ColorRect:
		return existing as ColorRect
	var rect := ColorRect.new()
	rect.name = "TransitionRect"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	return rect
