extends Camera2D
class_name GCCamera2D
## Flexible camera with multiple modes. Assign a mode or switch at runtime.

enum Mode { FOLLOW, FIXED, ROOM_LOCKED, FREE, RAIL }

@export var mode: Mode = Mode.FOLLOW
@export var follow_target: Node2D
@export var smoothing := 5.0
@export var room_size := Vector2(640, 360)
@export var rail_path: Path2D
@export var rail_speed := 100.0

var _rail_offset := 0.0
var _shake_strength := 0.0
var _shake_duration := 0.0
var _shake_remaining := 0.0


func _physics_process(delta: float) -> void:
	match mode:
		Mode.FOLLOW:
			_do_follow(delta)
		Mode.FIXED:
			pass  # Camera stays where placed
		Mode.ROOM_LOCKED:
			_do_room_lock()
		Mode.FREE:
			_do_free(delta)
		Mode.RAIL:
			_do_rail(delta)

	_process_shake(delta)


func set_follow_target(target: Node2D) -> void:
	follow_target = target


func snap_to_target() -> void:
	if follow_target:
		global_position = follow_target.global_position


func _do_follow(delta: float) -> void:
	if follow_target == null:
		return
	global_position = global_position.lerp(follow_target.global_position, smoothing * delta)


func _do_room_lock() -> void:
	if follow_target == null:
		return
	var target_pos := follow_target.global_position
	var room_x := floorf(target_pos.x / room_size.x) * room_size.x + room_size.x * 0.5
	var room_y := floorf(target_pos.y / room_size.y) * room_size.y + room_size.y * 0.5
	global_position = Vector2(room_x, room_y)


func _do_free(delta: float) -> void:
	var input_dir := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	global_position += input_dir * smoothing * 100.0 * delta


func _do_rail(delta: float) -> void:
	if rail_path == null or rail_path.curve == null:
		return
	_rail_offset += rail_speed * delta
	var length := rail_path.curve.get_baked_length()
	_rail_offset = clampf(_rail_offset, 0.0, length)
	global_position = rail_path.curve.sample_baked(_rail_offset)


## Trigger a screen shake. Stacks by taking the greater strength.
func shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(duration, 0.01)
	_shake_remaining = _shake_duration


func _process_shake(delta: float) -> void:
	if _shake_remaining <= 0.0:
		return
	_shake_remaining -= delta
	if _shake_remaining <= 0.0:
		_shake_remaining = 0.0
		_shake_strength = 0.0
		offset = Vector2.ZERO
		return
	var decay := _shake_remaining / _shake_duration
	var current_strength := _shake_strength * decay
	offset = Vector2(
		randf_range(-current_strength, current_strength),
		randf_range(-current_strength, current_strength)
	)
