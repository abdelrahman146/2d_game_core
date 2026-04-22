extends GutTest
## Tests for GCShoot trigger modes and gate behavior.

const GCCharacterHost2D = preload("res://addons/game_core/actors/gc_character_host.gd")
const GCShoot = preload("res://addons/game_core/behaviors/combat/gc_shoot.gd")


var _host: GCCharacterHost2D
var _shoot: GCShoot


func before_each() -> void:
	_host = GCCharacterHost2D.new()
	_shoot = GCShoot.new()
	_shoot.projectile_scene = _make_simple_scene()
	_host.add_child(_shoot)
	add_child_autoqfree(_host)
	_host.set_process(false)
	_host.set_physics_process(false)
	_host.local_state[&"facing_direction"] = 1


func test_auto_fire_uses_target_detected_by_default() -> void:
	_host.local_state[&"target_detected"] = true
	watch_signals(_shoot)
	_shoot.on_physics(_host, 0.016)
	assert_signal_emitted(_shoot, "shot_fired")
	assert_eq(_shoot._timer, _shoot.cooldown)
	_cleanup_shot(0)


func test_auto_fire_does_not_trigger_without_target_in_default_mode() -> void:
	watch_signals(_shoot)
	_shoot.on_physics(_host, 0.016)
	assert_signal_not_emitted(_shoot, "shot_fired")


func test_timer_mode_fires_without_target_detected() -> void:
	_shoot.trigger_mode = GCShoot.TriggerMode.TIMER
	watch_signals(_shoot)
	_shoot.on_physics(_host, 0.016)
	assert_signal_emitted(_shoot, "shot_fired")
	_cleanup_shot(0)


func test_gate_state_blocks_auto_fire_when_not_matched() -> void:
	_shoot.gate_state_key = &"can_fire"
	_host.local_state[&"target_detected"] = true
	watch_signals(_shoot)
	_shoot.on_physics(_host, 0.016)
	assert_signal_not_emitted(_shoot, "shot_fired")


func test_gate_state_allows_auto_fire_when_matched() -> void:
	_shoot.gate_state_key = &"can_fire"
	_host.local_state[&"can_fire"] = true
	_host.local_state[&"target_detected"] = true
	watch_signals(_shoot)
	_shoot.on_physics(_host, 0.016)
	assert_signal_emitted(_shoot, "shot_fired")
	_cleanup_shot(0)


func test_manual_fire_bypasses_auto_fire_gate_checks() -> void:
	_shoot.auto_fire = false
	_shoot.gate_state_key = &"can_fire"
	watch_signals(_shoot)
	_shoot.fire(_host)
	assert_signal_emitted(_shoot, "shot_fired")
	_cleanup_shot(0)


func _make_simple_scene() -> PackedScene:
	var node := Node2D.new()
	var scene := PackedScene.new()
	var result := scene.pack(node)
	node.free()
	assert_eq(result, OK)
	return scene


func _cleanup_shot(index: int) -> void:
	var params = get_signal_parameters(_shoot, "shot_fired", index)
	if params != null and params.size() > 0 and params[0] is Node:
		autoqfree(params[0] as Node)