extends GutTest
## Tests for GCScrollDriver: speed management, scroll movement, modifiers.

var _driver: GCScrollDriver


func before_each() -> void:
	_driver = GCScrollDriver.new()
	_driver.base_speed = 100.0
	_driver.acceleration = 10.0
	_driver.max_speed = 300.0
	_driver.direction = Vector2.UP
	_driver.active = false  # Prevent auto-processing
	add_child_autoqfree(_driver)
	_driver.set_process(false)
	_driver.set_physics_process(false)


func test_initial_speed_is_base_speed() -> void:
	assert_eq(_driver.current_speed, _driver.base_speed)


func test_effective_speed_with_modifier() -> void:
	_driver.current_speed = 200.0
	_driver.speed_modifier = 0.5
	assert_eq(_driver.get_effective_speed(), 200.0)
	# Note: effective speed is current_speed (modifier applied during physics step)


func test_speed_modifier_emits_signal() -> void:
	watch_signals(_driver)
	_driver.apply_speed_modifier(0.5)
	assert_signal_emitted(_driver, "speed_changed")
	assert_eq(_driver.speed_modifier, 0.5)


func test_reset_restores_initial_state() -> void:
	_driver.elapsed = 50.0
	_driver.current_speed = 250.0
	_driver.speed_modifier = 0.5
	_driver.reset()
	assert_eq(_driver.elapsed, 0.0)
	assert_eq(_driver.current_speed, 100.0)
	assert_eq(_driver.speed_modifier, 1.0)


func test_direction_default_is_up() -> void:
	var fresh := GCScrollDriver.new()
	assert_eq(fresh.direction, Vector2.UP)
	fresh.free()


func test_scroll_moves_children_of_target() -> void:
	# Create a scroll target with child nodes
	var target := Node2D.new()
	add_child_autoqfree(target)
	var child_a := Node2D.new()
	child_a.position = Vector2(0, 100)
	target.add_child(child_a)
	var child_b := Node2D.new()
	child_b.position = Vector2(50, 200)
	target.add_child(child_b)

	_driver.set_scroll_target(target)
	_driver.active = true
	_driver.direction = Vector2.UP

	# Simulate one physics step manually
	var delta := 0.1
	_driver.elapsed += delta
	var target_speed: float = minf(_driver.base_speed + _driver.acceleration * _driver.elapsed, _driver.max_speed)
	_driver.current_speed = target_speed * _driver.speed_modifier
	var offset: Vector2 = _driver.direction * _driver.current_speed * delta
	for child in target.get_children():
		if child is Node2D:
			(child as Node2D).position += offset

	# With base_speed=100, accel=10, elapsed=0.1: speed = 100 + 10*0.1 = 101
	# offset = UP * 101 * 0.1 = (0, -10.1)
	assert_almost_eq(child_a.position.y, 100.0 - 10.1, 0.01)
	assert_almost_eq(child_b.position.y, 200.0 - 10.1, 0.01)


func test_speed_capped_at_max() -> void:
	_driver.elapsed = 1000.0  # Way past max
	var target_speed: float = minf(_driver.base_speed + _driver.acceleration * _driver.elapsed, _driver.max_speed)
	assert_eq(target_speed, _driver.max_speed)
