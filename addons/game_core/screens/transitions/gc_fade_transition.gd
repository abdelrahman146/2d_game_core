extends "res://addons/game_core/screens/transitions/gc_transition.gd"
class_name GCFadeTransition
## Fades the screen to a color and back.

@export var color: Color = Color.BLACK
@export var duration: float = 0.3


func play_exit(canvas: CanvasLayer) -> void:
	var rect := _get_or_create_rect(canvas)
	rect.color = color
	rect.modulate.a = 0.0
	rect.visible = true
	var tween := canvas.get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	tween.tween_callback(func(): finished.emit())


func play_enter(canvas: CanvasLayer) -> void:
	var rect := _get_or_create_rect(canvas)
	rect.color = color
	rect.modulate.a = 1.0
	rect.visible = true
	var tween := canvas.get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		rect.visible = false
		finished.emit()
	)


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
