extends Resource
class_name GCTransition
## Base class for screen transitions. Extend to create custom animations.
## The router calls play_enter() and play_exit() during navigation.

signal finished


func play_enter(_canvas: CanvasLayer) -> void:
	finished.emit()


func play_exit(_canvas: CanvasLayer) -> void:
	finished.emit()
