extends GutTest
## Tests for GCLinearMotion velocity, gating, and lifetime cleanup.

const GCAreaHost2D = preload("res://addons/game_core/actors/gc_area_host.gd")
const GCLinearMotion = preload("res://addons/game_core/behaviors/movement/gc_linear_motion.gd")

var _host: GCAreaHost2D
var _motion: GCLinearMotion


func before_each() -> void:
	_host = GCAreaHost2D.new()
	_motion = GCLinearMotion.new()
	_motion.velocity = Vector2(0.0, 120.0)
	_host.add_child(_motion)
	add_child_autoqfree(_host)
	_host.set_process(false)
	_host.set_physics_process(false)


func test_moves_host_by_velocity() -> void:
	_motion.on_physics(_host, 0.5)
	assert_eq(_host.global_position, Vector2(0.0, 60.0))


func test_velocity_can_come_from_local_state() -> void:
	_motion.velocity_state_key = &"fall_velocity"
	_host.local_state[&"fall_velocity"] = Vector2(40.0, 0.0)
	_motion.on_physics(_host, 0.25)
	assert_eq(_host.global_position, Vector2(10.0, 0.0))


func test_active_gate_blocks_motion_until_matched() -> void:
	_motion.active_state_key = &"can_move"
	_motion.on_physics(_host, 0.5)
	assert_eq(_host.global_position, Vector2.ZERO)
	_host.local_state[&"can_move"] = true
	_motion.on_physics(_host, 0.5)
	assert_eq(_host.global_position, Vector2(0.0, 60.0))


func test_lifetime_emits_and_queues_host_free() -> void:
	_motion.lifetime = 0.25
	_motion.reset_lifetime()
	watch_signals(_motion)
	_motion.on_physics(_host, 0.25)
	assert_signal_emitted(_motion, "lifetime_finished")
	assert_true(_host.is_queued_for_deletion())


func test_lifetime_can_emit_without_freeing_host() -> void:
	_motion.lifetime = 0.25
	_motion.free_on_lifetime_end = false
	_motion.reset_lifetime()
	watch_signals(_motion)
	_motion.on_physics(_host, 0.25)
	assert_signal_emitted(_motion, "lifetime_finished")
	assert_false(_host.is_queued_for_deletion())


func test_local_space_velocity_rotates_with_host() -> void:
	_host.global_rotation = PI / 2.0
	_motion.use_local_space = true
	_motion.velocity = Vector2.RIGHT * 100.0
	_motion.on_physics(_host, 0.5)
	assert_almost_eq(_host.global_position.x, 0.0, 0.01)
	assert_almost_eq(_host.global_position.y, 50.0, 0.01)
