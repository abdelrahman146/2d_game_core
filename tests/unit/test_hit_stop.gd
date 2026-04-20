extends GutTest
## Tests for GCHitStop freeze utility.

const GCHitStop = preload("res://addons/game_core/core/gc_hit_stop.gd")

var _hit_stop: GCHitStop


func before_each() -> void:
	_hit_stop = GCHitStop.new()
	_hit_stop.default_duration = 0.05
	add_child_autoqfree(_hit_stop)
	# Ensure time_scale is normal before each test
	Engine.time_scale = 1.0


func after_each() -> void:
	# Safety: always restore time_scale even if a test fails
	Engine.time_scale = 1.0


func test_default_duration_export() -> void:
	assert_eq(_hit_stop.default_duration, 0.05)


func test_is_not_frozen_initially() -> void:
	assert_false(_hit_stop._is_frozen)


func test_freeze_emits_freeze_started() -> void:
	watch_signals(_hit_stop)
	# Start freeze but don't await — just verify the signal fires
	_hit_stop.freeze(0.01)
	assert_signal_emitted(_hit_stop, "freeze_started")


func test_freeze_sets_time_scale_to_zero() -> void:
	_hit_stop.freeze(1.0)  # Long duration so it stays frozen during assert
	assert_eq(Engine.time_scale, 0.0, "Engine.time_scale should be 0 during freeze")
	# Clean up
	Engine.time_scale = 1.0
	_hit_stop._unfreeze()


func test_unfreeze_restores_time_scale() -> void:
	_hit_stop._is_frozen = true
	Engine.time_scale = 0.0
	_hit_stop._unfreeze()
	assert_eq(Engine.time_scale, 1.0, "Engine.time_scale should be 1.0 after unfreeze")
	assert_false(_hit_stop._is_frozen)


func test_unfreeze_emits_freeze_ended() -> void:
	_hit_stop._is_frozen = true
	Engine.time_scale = 0.0
	watch_signals(_hit_stop)
	_hit_stop._unfreeze()
	assert_signal_emitted(_hit_stop, "freeze_ended")


func test_unfreeze_noop_when_not_frozen() -> void:
	watch_signals(_hit_stop)
	_hit_stop._unfreeze()
	assert_signal_not_emitted(_hit_stop, "freeze_ended")
	assert_eq(Engine.time_scale, 1.0)
