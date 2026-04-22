extends GutTest
## Tests for GCDrop trigger modes, timer cadence, and gate behavior.

const GCCharacterHost2D = preload("res://addons/game_core/actors/gc_character_host.gd")
const GCDrop = preload("res://addons/game_core/behaviors/combat/gc_drop.gd")


var _host: GCCharacterHost2D
var _drop: GCDrop


func before_each() -> void:
	_host = GCCharacterHost2D.new()
	_drop = GCDrop.new()
	_drop.drop_scene = _make_simple_scene()
	_host.add_child(_drop)
	add_child_autoqfree(_host)
	_host.set_process(false)
	_host.set_physics_process(false)


func test_auto_drop_uses_target_detected_by_default() -> void:
	_host.local_state[&"target_detected"] = true
	watch_signals(_drop)
	_drop.on_physics(_host, 0.016)
	assert_signal_emitted(_drop, "dropped")
	assert_eq(_drop._timer, _drop.cooldown)
	_cleanup_drop(0)


func test_timer_mode_drops_without_target_and_uses_timer_interval() -> void:
	_drop.trigger_mode = GCDrop.TriggerMode.TIMER
	_drop.timer_interval = 4.0
	watch_signals(_drop)
	_drop.on_physics(_host, 0.016)
	assert_signal_emitted(_drop, "dropped")
	assert_eq(_drop._timer, 4.0)
	_cleanup_drop(0)


func test_gate_state_blocks_auto_drop_when_not_matched() -> void:
	_drop.trigger_mode = GCDrop.TriggerMode.TIMER
	_drop.gate_state_key = &"can_drop"
	watch_signals(_drop)
	_drop.on_physics(_host, 0.016)
	assert_signal_not_emitted(_drop, "dropped")


func test_gate_state_allows_auto_drop_when_matched() -> void:
	_drop.trigger_mode = GCDrop.TriggerMode.TIMER
	_drop.gate_state_key = &"can_drop"
	_host.local_state[&"can_drop"] = true
	watch_signals(_drop)
	_drop.on_physics(_host, 0.016)
	assert_signal_emitted(_drop, "dropped")
	_cleanup_drop(0)


func test_drop_on_timer_preserves_legacy_timer_behavior_when_auto_drop_disabled() -> void:
	_drop.auto_drop = false
	_drop.drop_on_timer = true
	_drop.timer_interval = 1.5
	watch_signals(_drop)
	_drop.on_physics(_host, 0.016)
	assert_signal_emitted(_drop, "dropped")
	assert_eq(_drop._timer, 1.5)
	_cleanup_drop(0)


func test_manual_drop_bypasses_auto_drop_gate_checks() -> void:
	_drop.auto_drop = false
	_drop.gate_state_key = &"can_drop"
	watch_signals(_drop)
	_drop.drop(_host)
	assert_signal_emitted(_drop, "dropped")
	_cleanup_drop(0)


func _make_simple_scene() -> PackedScene:
	var node := Node2D.new()
	var scene := PackedScene.new()
	var result := scene.pack(node)
	node.free()
	assert_eq(result, OK)
	return scene


func _cleanup_drop(index: int) -> void:
	var params = get_signal_parameters(_drop, "dropped", index)
	if params != null and params.size() > 0 and params[0] is Node:
		autoqfree(params[0] as Node)