extends GutTest
## Tests for GCTargetAlignment axis gating.

const GCCharacterHost2D = preload("res://addons/game_core/actors/gc_character_host.gd")
const GCTargetAlignment = preload("res://addons/game_core/behaviors/sensing/gc_target_alignment.gd")


var _host: GCCharacterHost2D
var _target: Node2D
var _alignment: GCTargetAlignment


func before_each() -> void:
	_host = GCCharacterHost2D.new()
	_alignment = GCTargetAlignment.new()
	_host.add_child(_alignment)
	add_child_autoqfree(_host)
	_host.set_process(false)
	_host.set_physics_process(false)

	_target = Node2D.new()
	add_child_autoqfree(_target)
	_host.global_position = Vector2(100.0, 200.0)
	_target.global_position = Vector2(100.0, 200.0)
	_host.local_state[&"target_node"] = _target


func test_x_axis_alignment_passes_within_tolerance() -> void:
	_alignment.axis = GCTargetAlignment.Axis.X
	_alignment.tolerance = 12.0
	_target.global_position = Vector2(109.0, 260.0)
	_host._physics_process(0.016)
	assert_true(_host.local_state.get(&"target_aligned"))
	assert_eq(_host.local_state.get(&"target_alignment_delta"), 9.0)


func test_x_axis_alignment_fails_outside_tolerance() -> void:
	_alignment.axis = GCTargetAlignment.Axis.X
	_alignment.tolerance = 12.0
	_target.global_position = Vector2(113.5, 200.0)
	_host._physics_process(0.016)
	assert_false(_host.local_state.get(&"target_aligned"))
	assert_eq(_host.local_state.get(&"target_alignment_delta"), 13.5)


func test_y_axis_alignment_uses_vertical_band() -> void:
	_alignment.axis = GCTargetAlignment.Axis.Y
	_alignment.tolerance = 10.0
	_target.global_position = Vector2(40.0, 191.0)
	_host._physics_process(0.016)
	assert_true(_host.local_state.get(&"target_aligned"))
	assert_eq(_host.local_state.get(&"target_alignment_delta"), -9.0)


func test_invalid_target_resets_gate() -> void:
	_host.local_state[&"target_node"] = null
	_host.local_state[&"target_aligned"] = true
	_host.local_state[&"target_alignment_delta"] = 99.0
	_host._physics_process(0.016)
	assert_false(_host.local_state.get(&"target_aligned"))
	assert_eq(_host.local_state.get(&"target_alignment_delta"), 0.0)


func test_custom_keys_are_supported() -> void:
	_alignment.target_key = &"candidate"
	_alignment.aligned_key = &"same_lane"
	_alignment.delta_key = &"lane_delta"
	_alignment.axis = GCTargetAlignment.Axis.X
	_alignment.tolerance = 4.0
	_host.local_state.erase(&"target_node")
	_host.local_state[&"candidate"] = _target
	_target.global_position = Vector2(103.0, 120.0)
	_host._physics_process(0.016)
	assert_true(_host.local_state.get(&"same_lane"))
	assert_eq(_host.local_state.get(&"lane_delta"), 3.0)