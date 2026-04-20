extends GutTest
## Tests for GCCamera2D shake feature.

const GCCamera2D = preload("res://addons/game_core/world/gc_camera.gd")

var _camera: GCCamera2D


func before_each() -> void:
	_camera = GCCamera2D.new()
	_camera.mode = GCCamera2D.Mode.FIXED
	add_child_autoqfree(_camera)
	_camera.set_process(false)
	_camera.set_physics_process(false)


func test_shake_sets_remaining_duration() -> void:
	_camera.shake(10.0, 0.5)
	assert_gt(_camera._shake_remaining, 0.0, "Shake remaining should be positive after shake()")
	assert_eq(_camera._shake_strength, 10.0)


func test_shake_offset_changes_during_shake() -> void:
	_camera.shake(50.0, 1.0)
	# Manually tick physics to process shake
	_camera._process_shake(0.016)
	var offset_after := _camera.offset
	# With strength=50 there should be a non-zero offset (statistically near-certain)
	# We run a few ticks to increase probability
	var any_nonzero := offset_after != Vector2.ZERO
	for i in range(10):
		_camera._process_shake(0.016)
		if _camera.offset != Vector2.ZERO:
			any_nonzero = true
			break
	assert_true(any_nonzero, "Offset should be non-zero during active shake")


func test_shake_decays_to_zero() -> void:
	_camera.shake(10.0, 0.1)
	# Tick past the full duration
	_camera._process_shake(0.2)
	assert_eq(_camera.offset, Vector2.ZERO, "Offset should return to zero after shake ends")
	assert_eq(_camera._shake_remaining, 0.0)
	assert_eq(_camera._shake_strength, 0.0)


func test_shake_stacks_with_greater_strength() -> void:
	_camera.shake(5.0, 1.0)
	_camera.shake(20.0, 0.5)
	assert_eq(_camera._shake_strength, 20.0, "Strength should be the greater value")


func test_no_shake_when_not_triggered() -> void:
	_camera._process_shake(0.016)
	assert_eq(_camera.offset, Vector2.ZERO, "No offset when shake was never triggered")
