extends Control
class_name GCVirtualJoystick
## Touch-screen virtual joystick for mobile games.
## Place inside a CanvasLayer or GCHudLayer. Outputs a direction vector
## that game code reads each frame.
##
## Two modes:
##   FIXED  — joystick stays where placed in the editor.
##   DYNAMIC — joystick appears at the touch point, recenters each press.
##
## The node's rect size defines the touch-sensitive area.
## The drawn joystick base fits inside that area, centered.

signal direction_changed(direction: Vector2)

enum JoystickMode { FIXED, DYNAMIC }
enum VisibilityMode { ALWAYS, WHEN_PRESSED }

@export_group("Behavior")
## Fixed keeps the joystick in place. Dynamic moves it to the touch point.
@export var joystick_mode: JoystickMode = JoystickMode.FIXED
## Tilt below this ratio is ignored (0–1, fraction of base radius).
@export_range(0.0, 0.9, 0.01) var dead_zone: float = 0.15

@export_group("Visuals")
## When WHEN_PRESSED, the joystick is invisible until touched.
@export var visibility_mode: VisibilityMode = VisibilityMode.ALWAYS
## Optional texture for the base ring. If null, a circle is drawn.
@export var base_texture: Texture2D
## Optional texture for the handle. If null, a circle is drawn.
@export var handle_texture: Texture2D
## Color of the default-drawn base ring.
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.25)
## Color of the default-drawn handle circle.
@export var handle_color: Color = Color(1.0, 1.0, 1.0, 0.6)
## Handle radius as a fraction of the base radius (0–1).
@export_range(0.1, 0.8, 0.01) var handle_ratio: float = 0.35

## Current output direction. Length 0–1, zero when released.
var direction: Vector2 = Vector2.ZERO:
	set(value):
		if direction != value:
			direction = value
			direction_changed.emit(direction)

## True while the player is touching the joystick.
var is_pressed: bool = false

# Internal tracking
var _touch_index: int = -1
var _base_center: Vector2 = Vector2.ZERO
var _base_radius: float = 0.0
var _handle_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_recalculate_geometry()
	_update_visibility()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_geometry()


func _recalculate_geometry() -> void:
	_base_radius = minf(size.x, size.y) * 0.5
	_base_center = size * 0.5


func _update_visibility() -> void:
	if visibility_mode == VisibilityMode.WHEN_PRESSED:
		visible = is_pressed
	else:
		visible = true


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only accept if no finger is tracked and touch is inside our rect
		if _touch_index != -1:
			return
		var local_pos := _to_local_pos(event.position)
		if not _is_inside_rect(local_pos):
			return
		_touch_index = event.index
		is_pressed = true
		if joystick_mode == JoystickMode.DYNAMIC:
			_base_center = local_pos
		_handle_offset = Vector2.ZERO
		direction = Vector2.ZERO
		_update_visibility()
		queue_redraw()
	else:
		# Release
		if event.index != _touch_index:
			return
		_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var local_pos := _to_local_pos(event.position)
	var diff := local_pos - _base_center
	var dist := diff.length()
	# Clamp to base radius
	if dist > _base_radius:
		diff = diff.normalized() * _base_radius
		dist = _base_radius
	_handle_offset = diff
	# Calculate normalized direction with dead zone
	var ratio := dist / _base_radius if _base_radius > 0.0 else 0.0
	if ratio < dead_zone:
		direction = Vector2.ZERO
	else:
		# Remap from dead_zone..1 to 0..1
		var remapped := (ratio - dead_zone) / (1.0 - dead_zone)
		direction = diff.normalized() * remapped
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	is_pressed = false
	_handle_offset = Vector2.ZERO
	direction = Vector2.ZERO
	if joystick_mode == JoystickMode.DYNAMIC:
		_base_center = size * 0.5
	_update_visibility()
	queue_redraw()


func _to_local_pos(screen_pos: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * screen_pos


func _is_inside_rect(local_pos: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(local_pos)


func _draw() -> void:
	if not is_pressed and visibility_mode == VisibilityMode.WHEN_PRESSED:
		return
	_draw_base()
	_draw_handle()


func _draw_base() -> void:
	if base_texture:
		var tex_size := base_texture.get_size()
		var scale_factor := (_base_radius * 2.0) / maxf(tex_size.x, tex_size.y)
		var draw_size := tex_size * scale_factor
		var draw_pos := _base_center - draw_size * 0.5
		draw_texture_rect(base_texture, Rect2(draw_pos, draw_size), false)
	else:
		# Draw ring
		draw_arc(_base_center, _base_radius, 0.0, TAU, 64, base_color, 2.0)
		draw_circle(_base_center, _base_radius, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.3))


func _draw_handle() -> void:
	var handle_pos := _base_center + _handle_offset
	var handle_r := _base_radius * handle_ratio
	if handle_texture:
		var tex_size := handle_texture.get_size()
		var scale_factor := (handle_r * 2.0) / maxf(tex_size.x, tex_size.y)
		var draw_size := tex_size * scale_factor
		var draw_pos := handle_pos - draw_size * 0.5
		draw_texture_rect(handle_texture, Rect2(draw_pos, draw_size), false)
	else:
		draw_circle(handle_pos, handle_r, handle_color)
