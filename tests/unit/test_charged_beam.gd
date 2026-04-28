extends GutTest
## Tests for GCChargedBeam timing, gating, and hitbox toggling.

const GCCharacterHost2D = preload("res://addons/game_core/actors/gc_character_host.gd")
const GCChargedBeam = preload("res://addons/game_core/behaviors/combat/gc_charged_beam.gd")


var _host: GCCharacterHost2D
var _beam: GCChargedBeam
var _beam_root: Area2D
var _target: Node2D
var _beam_ray: RayCast2D


func before_each() -> void:
	_host = GCCharacterHost2D.new()
	_beam_root = Area2D.new()
	_beam_root.name = "BeamRoot"
	_beam_root.monitoring = true
	_beam_root.monitorable = true
	var shape := CollisionShape2D.new()
	shape.name = "BeamShape"
	_beam_root.add_child(shape)
	_host.add_child(_beam_root)
	_beam_ray = RayCast2D.new()
	_beam_ray.name = "BeamRay"
	_beam_ray.enabled = true
	_host.add_child(_beam_ray)

	_beam = GCChargedBeam.new()
	_beam.beam_root_path = ^"BeamRoot"
	_beam.beam_collision_path = ^"BeamRoot"
	_beam.length_raycast_path = ^"BeamRay"
	_beam.windup_time = 0.5
	_beam.active_time = 0.25
	_beam.cooldown = 0.75
	_beam.max_range = 300.0
	_beam.default_length = 120.0
	_host.add_child(_beam)

	add_child_autoqfree(_host)
	_host.set_process(false)
	_host.set_physics_process(false)

	_target = Node2D.new()
	add_child_autoqfree(_target)
	_target.global_position = Vector2(100.0, 50.0)


func test_host_ready_starts_idle_and_disables_hitbox() -> void:
	assert_eq(_host.local_state.get(&"beam_state"), &"idle")
	assert_false(_host.local_state.get(&"beam_active"))
	assert_false(_beam_root.visible)
	assert_false(_beam_root.monitoring)


func test_auto_fire_uses_target_detected_by_default() -> void:
	_host.local_state[&"target_detected"] = true
	watch_signals(_beam)
	_beam.on_physics(_host, 0.016)
	assert_eq(_host.local_state.get(&"beam_state"), &"windup")
	assert_signal_emitted(_beam, "beam_windup_started")
	assert_false(_beam_root.visible)
	assert_false(_beam_root.monitoring)


func test_gate_state_blocks_auto_fire_when_not_matched() -> void:
	_beam.gate_state_key = &"can_beam"
	_host.local_state[&"target_detected"] = true
	watch_signals(_beam)
	_beam.on_physics(_host, 0.016)
	assert_eq(_host.local_state.get(&"beam_state"), &"idle")
	assert_signal_not_emitted(_beam, "beam_windup_started")


func test_windup_transitions_to_active_and_enables_hitbox() -> void:
	_host.local_state[&"target_detected"] = true
	watch_signals(_beam)
	_beam.fire(_host)
	_beam.on_physics(_host, 0.5)
	assert_eq(_host.local_state.get(&"beam_state"), &"active")
	assert_true(_host.local_state.get(&"beam_active"))
	assert_true(_beam_root.visible)
	assert_true(_beam_root.monitoring)
	assert_signal_emitted(_beam, "beam_activated")


func test_active_transitions_to_cooldown_then_idle() -> void:
	_beam.fire(_host)
	_beam.on_physics(_host, 0.5)
	_beam.on_physics(_host, 0.25)
	assert_eq(_host.local_state.get(&"beam_state"), &"cooldown")
	assert_false(_host.local_state.get(&"beam_active"))
	assert_false(_beam_root.visible)
	assert_false(_beam_root.monitoring)
	_beam.on_physics(_host, 0.75)
	assert_eq(_host.local_state.get(&"beam_state"), &"idle")


func test_manual_fire_bypasses_auto_fire_gate_checks() -> void:
	_beam.auto_fire = false
	_beam.gate_state_key = &"can_beam"
	watch_signals(_beam)
	_beam.fire(_host)
	assert_eq(_host.local_state.get(&"beam_state"), &"windup")
	assert_signal_emitted(_beam, "beam_windup_started")


func test_target_node_aim_sets_direction_toward_target() -> void:
	_beam.aim_mode = GCChargedBeam.AimMode.TARGET_NODE
	_host.local_state[&"target_node"] = _target
	_host.global_position = Vector2.ZERO
	_target.global_position = Vector2(100.0, 0.0)
	_beam.fire(_host)
	assert_eq(_host.local_state.get(&"beam_direction"), Vector2.RIGHT)


func test_length_raycast_clamps_beam_to_world_geometry() -> void:
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10.0, 200.0)
	wall_shape.shape = rect
	wall.add_child(wall_shape)
	add_child_autoqfree(wall)
	wall.global_position = Vector2(100.0, 0.0)
	await get_tree().physics_frame

	_beam.fixed_direction = Vector2.RIGHT
	_beam.aim_mode = GCChargedBeam.AimMode.FIXED_DIRECTION
	_host.global_position = Vector2.ZERO
	_beam.fire(_host)
	var beam_length: float = _host.local_state.get(&"beam_length", 0.0)
	var hit_position: Vector2 = _host.local_state.get(&"beam_hit_position", Vector2.ZERO)
	assert_true(beam_length > 80.0)
	assert_true(beam_length < 110.0)
	assert_true(hit_position.x > 80.0)
	assert_true(hit_position.x < 110.0)
