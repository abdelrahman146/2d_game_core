extends GutTest
## Tests for GCVirtualJoystick geometry, direction calculation, and state.

const GCVirtualJoystick = preload("res://addons/game_core/input/gc_virtual_joystick.gd")

var _joy: GCVirtualJoystick


func before_each() -> void:
	_joy = GCVirtualJoystick.new()
	_joy.size = Vector2(200, 200)
	_joy.position = Vector2.ZERO
	_joy.dead_zone = 0.15
	add_child_autoqfree(_joy)


func test_initial_direction_is_zero() -> void:
	assert_eq(_joy.direction, Vector2.ZERO)
	assert_false(_joy.is_pressed)


func test_base_radius_matches_half_size() -> void:
	assert_eq(_joy._base_radius, 100.0)
	assert_eq(_joy._base_center, Vector2(100, 100))


func test_base_radius_updates_on_resize() -> void:
	_joy.size = Vector2(300, 300)
	_joy._recalculate_geometry()
	assert_eq(_joy._base_radius, 150.0)
	assert_eq(_joy._base_center, Vector2(150, 150))


func test_non_square_uses_smaller_dimension() -> void:
	_joy.size = Vector2(400, 200)
	_joy._recalculate_geometry()
	assert_eq(_joy._base_radius, 100.0, "Should use min(width, height) / 2")


func test_release_resets_state() -> void:
	_joy.is_pressed = true
	_joy._handle_offset = Vector2(50, 0)
	_joy.direction = Vector2(1, 0)
	_joy._touch_index = 0
	_joy._release()
	assert_false(_joy.is_pressed)
	assert_eq(_joy.direction, Vector2.ZERO)
	assert_eq(_joy._handle_offset, Vector2.ZERO)
	assert_eq(_joy._touch_index, -1)


func test_direction_signal_emitted_on_change() -> void:
	watch_signals(_joy)
	_joy.direction = Vector2(0.5, 0.0)
	assert_signal_emitted(_joy, "direction_changed")


func test_direction_signal_not_emitted_when_same() -> void:
	_joy.direction = Vector2.ZERO
	watch_signals(_joy)
	_joy.direction = Vector2.ZERO
	assert_signal_not_emitted(_joy, "direction_changed")


func test_dynamic_mode_recenters_on_release() -> void:
	_joy.joystick_mode = GCVirtualJoystick.JoystickMode.DYNAMIC
	_joy._base_center = Vector2(50, 50)  # Simulate a dynamic touch offset
	_joy._release()
	assert_eq(_joy._base_center, Vector2(100, 100), "Dynamic mode should recenter on release")


func test_fixed_mode_keeps_center_on_release() -> void:
	_joy.joystick_mode = GCVirtualJoystick.JoystickMode.FIXED
	var original_center := _joy._base_center
	_joy._release()
	assert_eq(_joy._base_center, original_center, "Fixed mode should keep center on release")


func test_visibility_mode_always() -> void:
	_joy.visibility_mode = GCVirtualJoystick.VisibilityMode.ALWAYS
	_joy._update_visibility()
	assert_true(_joy.visible)


func test_visibility_mode_when_pressed_hides() -> void:
	_joy.visibility_mode = GCVirtualJoystick.VisibilityMode.WHEN_PRESSED
	_joy.is_pressed = false
	_joy._update_visibility()
	assert_false(_joy.visible)


func test_visibility_mode_when_pressed_shows() -> void:
	_joy.visibility_mode = GCVirtualJoystick.VisibilityMode.WHEN_PRESSED
	_joy.is_pressed = true
	_joy._update_visibility()
	assert_true(_joy.visible)
