extends Node
class_name GCScrollDriver
## Drives scroll movement for streaming chunk-based worlds.
## Moves all children of the target node in a direction at increasing speed.
## Connect to a GCStreamChunkSource for chunk lifecycle management.

signal speed_changed(effective_speed: float)

## Base scroll speed in pixels per second.
@export var base_speed: float = 100.0

## Speed increase per second (linear acceleration).
@export var acceleration: float = 2.0

## Maximum speed cap in pixels per second.
@export var max_speed: float = 400.0

## Scroll direction. Vector2.UP means chunks move upward (player "falls" down).
@export var direction: Vector2 = Vector2.UP

## If true, scrolling is active. Set to false to pause scroll.
@export var active: bool = true

## The GCStreamChunkSource resource to drive (optional — for lifecycle updates).
@export var chunk_source: Resource  # GCStreamChunkSource

## Viewport size along the scroll axis (set at runtime or export).
@export var viewport_scroll_size: float = 640.0

## Current speed modifier. Set via set_speed_modifier() (e.g., 0.5 when wall-sliding).
var speed_modifier: float = 1.0

## Read-only: current effective speed after modifier.
var current_speed: float = 0.0

## Total elapsed time since scroll started.
var elapsed: float = 0.0

var _scroll_target: Node2D


func _ready() -> void:
	current_speed = base_speed


func _physics_process(delta: float) -> void:
	if not active:
		return

	elapsed += delta

	# Calculate target speed with acceleration
	var target_speed := minf(base_speed + acceleration * elapsed, max_speed)
	current_speed = target_speed * speed_modifier

	# Find scroll target (chunk root from world controller or manual assignment)
	var target := _get_scroll_target()
	if target == null:
		return

	# Move all chunk children
	var offset := direction * current_speed * delta
	for child in target.get_children():
		if child is Node2D:
			(child as Node2D).position += offset

	# Update chunk source lifecycle if connected
	if chunk_source and chunk_source.has_method("update"):
		chunk_source.advance_time(delta)
		# For Vector2.UP scroll: leading edge is bottom of screen, trailing is top
		var leading_edge := viewport_scroll_size  # Bottom of viewport
		var trailing_edge := 0.0  # Top of viewport
		chunk_source.update(leading_edge, trailing_edge, viewport_scroll_size)


## Set the node whose children will be scrolled.
func set_scroll_target(target: Node2D) -> void:
	_scroll_target = target


## Set the speed modifier and emit speed_changed signal.
func apply_speed_modifier(value: float) -> void:
	speed_modifier = value
	speed_changed.emit(get_effective_speed())


## Get the current effective speed (base + acceleration + modifier).
func get_effective_speed() -> float:
	return current_speed


## Reset elapsed time and speed to initial values.
func reset() -> void:
	elapsed = 0.0
	current_speed = base_speed
	speed_modifier = 1.0


func _get_scroll_target() -> Node2D:
	if _scroll_target:
		return _scroll_target
	# Try to find world root from sibling GCWorldController
	var parent := get_parent()
	if parent == null:
		return null
	for sibling in parent.get_children():
		if sibling is GCWorldController:
			var root := (sibling as GCWorldController).get_world_root()
			if root is Node2D:
				return root as Node2D
	return null
