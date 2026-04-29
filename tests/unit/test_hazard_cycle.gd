extends GutTest
## Tests for GCHazardCycle timing, local state, and collision toggling.

const GCStaticHost2D = preload("res://addons/game_core/actors/gc_static_host.gd")
const GCHazardCycle = preload("res://addons/game_core/behaviors/combat/gc_hazard_cycle.gd")

var _host: GCStaticHost2D
var _cycle: GCHazardCycle
var _damage_area: Area2D
var _damage_shape: CollisionShape2D
var _visual: Sprite2D


func before_each() -> void:
	_host = GCStaticHost2D.new()
	_visual = Sprite2D.new()
	_visual.name = "Visual"
	_host.add_child(_visual)
	_damage_area = Area2D.new()
	_damage_area.name = "DamageArea"
	_damage_area.monitoring = true
	_damage_area.monitorable = true
	_damage_shape = CollisionShape2D.new()
	_damage_area.add_child(_damage_shape)
	_host.add_child(_damage_area)
	_cycle = GCHazardCycle.new()
	_cycle.visual_root_path = ^"Visual"
	_cycle.collision_path = ^"DamageArea"
	_cycle.toggle_visual = true
	_cycle.windup_time = 0.5
	_cycle.active_time = 0.25
	_cycle.cooldown_time = 0.75
	_host.add_child(_cycle)
	add_child_autoqfree(_host)
	_host.set_process(false)
	_host.set_physics_process(false)


func test_host_ready_starts_idle_and_disables_collision() -> void:
	assert_eq(_host.local_state.get(&"hazard_state"), &"idle")
	assert_false(_host.local_state.get(&"hazard_active"))
	assert_false(_visual.visible)
	assert_false(_damage_area.monitoring)
	assert_true(_damage_shape.disabled)


func test_auto_start_enters_windup_after_initial_delay() -> void:
	var host := GCStaticHost2D.new()
	var cycle := GCHazardCycle.new()
	cycle.initial_delay = 0.25
	host.add_child(cycle)
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)

	watch_signals(cycle)
	cycle.on_physics(host, 0.10)
	assert_eq(host.local_state.get(&"hazard_state"), &"idle")
	assert_signal_not_emitted(cycle, "hazard_windup_started")
	cycle.on_physics(host, 0.15)
	assert_eq(host.local_state.get(&"hazard_state"), &"windup")
	assert_signal_emitted(cycle, "hazard_windup_started")


func test_windup_transitions_to_active_and_enables_collision() -> void:
	watch_signals(_cycle)
	_cycle.start_cycle(_host)
	_cycle.on_physics(_host, 0.5)
	assert_eq(_host.local_state.get(&"hazard_state"), &"active")
	assert_true(_host.local_state.get(&"hazard_active"))
	assert_true(_visual.visible)
	assert_true(_damage_area.monitoring)
	assert_false(_damage_shape.disabled)
	assert_signal_emitted(_cycle, "hazard_activated")


func test_active_transitions_to_cooldown_then_loops() -> void:
	_cycle.start_cycle(_host)
	_cycle.on_physics(_host, 0.5)
	_cycle.on_physics(_host, 0.25)
	assert_eq(_host.local_state.get(&"hazard_state"), &"cooldown")
	assert_false(_host.local_state.get(&"hazard_active"))
	assert_false(_damage_area.monitoring)
	_cycle.on_physics(_host, 0.75)
	assert_eq(_host.local_state.get(&"hazard_state"), &"windup")


func test_gate_state_blocks_auto_start() -> void:
	_cycle.gate_state_key = &"can_cycle"
	_cycle.stop_cycle(_host)
	watch_signals(_cycle)
	_cycle.on_physics(_host, 0.016)
	assert_eq(_host.local_state.get(&"hazard_state"), &"idle")
	assert_signal_not_emitted(_cycle, "hazard_windup_started")


func test_start_active_keeps_collision_enabled_until_stopped() -> void:
	var host := GCStaticHost2D.new()
	var area := Area2D.new()
	area.name = "DamageArea"
	host.add_child(area)
	var cycle := GCHazardCycle.new()
	cycle.start_active = true
	cycle.active_time = -1.0
	host.add_child(cycle)
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)

	assert_eq(host.local_state.get(&"hazard_state"), &"active")
	assert_true(host.local_state.get(&"hazard_active"))
	assert_true(area.monitoring)
	cycle.on_physics(host, 20.0)
	assert_eq(host.local_state.get(&"hazard_state"), &"active")
	cycle.stop_cycle(host)
	assert_eq(host.local_state.get(&"hazard_state"), &"idle")
	assert_false(area.monitoring)
