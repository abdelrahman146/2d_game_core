extends GutTest
## Tests for actor host behavior dispatch: phase ordering, lifecycle hooks, enabled toggle.
## All hosts have engine processing disabled. We call _physics_process manually.

## Shared log of all execution events — proves global ordering across behaviors.
static var _log: Array[String] = []


class OrderTracker extends GCBehavior:
	var id: String

	func _init(p_id: String = "", p_phase: Phase = Phase.ACT) -> void:
		id = p_id
		phase = p_phase

	func on_host_ready(_host: Node) -> void:
		var test_script = load("res://tests/unit/test_character_host.gd")
		test_script._log.append("ready:" + id)

	func on_process(_host: Node, _delta: float) -> void:
		var test_script = load("res://tests/unit/test_character_host.gd")
		test_script._log.append("process:" + id)

	func on_physics(_host: Node, _delta: float) -> void:
		var test_script = load("res://tests/unit/test_character_host.gd")
		test_script._log.append("physics:" + id)

	func on_host_destroyed(_host: Node) -> void:
		var test_script = load("res://tests/unit/test_character_host.gd")
		test_script._log.append("destroyed:" + id)


func before_each() -> void:
	_log.clear()


## Creates a host with trackers added as children, adds to tree with
## processing disabled, returns the host.
func _make_host(configs: Array) -> CharacterBody2D:
	var host := GCCharacterHost2D.new()
	for cfg in configs:
		var t := OrderTracker.new(cfg[0], cfg[1])
		host.add_child(t)
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)
	return host


func test_on_host_ready_called_for_each_behavior() -> void:
	_make_host([["a", GCBehavior.Phase.ACT], ["b", GCBehavior.Phase.SENSE]])
	assert_has(_log, "ready:a")
	assert_has(_log, "ready:b")


func test_behaviors_sorted_by_phase_sense_before_act() -> void:
	# Add ACT first, then SENSE - phase order should still hold
	var host := _make_host([["act", GCBehavior.Phase.ACT], ["sense", GCBehavior.Phase.SENSE]])
	_log.clear()
	host._physics_process(0.016)
	var sense_idx := _log.find("physics:sense")
	var act_idx := _log.find("physics:act")
	assert_true(sense_idx >= 0, "sense physics was called")
	assert_true(act_idx >= 0, "act physics was called")
	assert_true(sense_idx < act_idx, "SENSE phase runs before ACT phase")


func test_full_phase_order_sense_decide_act_present() -> void:
	var host := _make_host([
		["present", GCBehavior.Phase.PRESENT],
		["act", GCBehavior.Phase.ACT],
		["decide", GCBehavior.Phase.DECIDE],
		["sense", GCBehavior.Phase.SENSE],
	])
	_log.clear()
	host._physics_process(0.016)
	var physics_log: Array[String] = []
	for entry in _log:
		if entry.begins_with("physics:"):
			physics_log.append(entry)
	assert_eq(physics_log, ["physics:sense", "physics:decide", "physics:act", "physics:present"])


func test_disabled_behavior_skipped_during_dispatch() -> void:
	var host := _make_host([["skip", GCBehavior.Phase.ACT]])
	# Disable the only behavior
	for child in host.get_children():
		if child is GCBehavior:
			child.enabled = false
	_log.clear()
	host._physics_process(0.016)
	assert_does_not_have(_log, "physics:skip")


func test_re_enabled_behavior_dispatched_again() -> void:
	var host := _make_host([["toggle", GCBehavior.Phase.ACT]])
	var behavior: GCBehavior = null
	for child in host.get_children():
		if child is GCBehavior:
			behavior = child
	behavior.enabled = false
	_log.clear()
	host._physics_process(0.016)
	assert_does_not_have(_log, "physics:toggle")
	behavior.enabled = true
	host._physics_process(0.016)
	assert_has(_log, "physics:toggle")


func test_on_host_destroyed_called_on_tree_exit() -> void:
	var host := GCCharacterHost2D.new()
	var a := OrderTracker.new("a", GCBehavior.Phase.ACT)
	var b := OrderTracker.new("b", GCBehavior.Phase.ACT)
	host.add_child(a)
	host.add_child(b)
	add_child(host)
	host.set_process(false)
	host.set_physics_process(false)
	_log.clear()
	# Remove from tree — this triggers _exit_tree -> on_host_destroyed
	remove_child(host)
	# Check global log for reverse order (b before a)
	var a_idx := _log.find("destroyed:a")
	var b_idx := _log.find("destroyed:b")
	# Free immediately — children freed with parent
	host.free()
	assert_true(a_idx >= 0, "a got destroyed callback")
	assert_true(b_idx >= 0, "b got destroyed callback")
	assert_true(b_idx < a_idx, "b destroyed before a (reverse order)")


func test_local_state_accessible_from_behaviors() -> void:
	var host := _make_host([])
	host.local_state[&"test_key"] = 42
	assert_eq(host.local_state[&"test_key"], 42)


func test_entity_tags_and_has_tag() -> void:
	var host := GCCharacterHost2D.new()
	host.entity_tags = PackedStringArray(["enemy", "flying"])
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)
	assert_true(host.has_tag(&"enemy"))
	assert_true(host.has_tag(&"flying"))
	assert_false(host.has_tag(&"player"))


func test_get_behavior_finds_by_script() -> void:
	var host := _make_host([["find_me", GCBehavior.Phase.ACT]])
	var found: GCBehavior = host.get_behavior(OrderTracker)
	assert_not_null(found)
	assert_true(found is OrderTracker)


func test_get_behavior_returns_null_when_not_found() -> void:
	var host := _make_host([])
	var found: GCBehavior = host.get_behavior(null)
	assert_null(found)
