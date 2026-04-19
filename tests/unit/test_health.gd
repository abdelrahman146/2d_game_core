extends GutTest
## Tests for GCHealth behavior: damage, heal, death, invincibility.
## Hosts have processing disabled — on_physics is called manually.

const GCCharacterHost2D = preload("res://addons/game_core/actors/gc_character_host.gd")
const GCHealth = preload("res://addons/game_core/behaviors/combat/gc_health.gd")


var _host: CharacterBody2D
var _health: GCHealth


func before_each() -> void:
	_host = GCCharacterHost2D.new()
	_health = GCHealth.new()
	_health.max_health = 5
	_host.add_child(_health)
	add_child_autoqfree(_host)
	# Disable engine processing — behaviors only run when we call manually
	_host.set_process(false)
	_host.set_physics_process(false)


func test_initial_health_set_to_max() -> void:
	assert_eq(_host.local_state.get(&"health"), 5)
	assert_eq(_host.local_state.get(&"max_health"), 5)
	assert_true(_host.local_state.get(&"is_alive"))


func test_take_damage_reduces_health() -> void:
	_health.take_damage(_host, 2)
	assert_eq(_host.local_state.get(&"health"), 3)


func test_take_damage_emits_damaged_signal() -> void:
	watch_signals(_health)
	var source: Node = autofree(Node.new()) as Node
	_health.take_damage(_host, 1, source)
	assert_signal_emitted_with_parameters(_health, "damaged", [1, source])


func test_take_damage_sets_just_hit() -> void:
	_health.take_damage(_host, 1)
	assert_true(_host.local_state.get(&"just_hit"))


func test_health_cannot_go_below_zero() -> void:
	_health.take_damage(_host, 100)
	assert_eq(_host.local_state.get(&"health"), 0)


func test_death_when_health_reaches_zero() -> void:
	watch_signals(_health)
	_health.take_damage(_host, 5)
	assert_false(_host.local_state.get(&"is_alive"))
	assert_signal_emitted(_health, "died")


func test_no_damage_after_death() -> void:
	_health.take_damage(_host, 5)
	watch_signals(_health)
	_health.take_damage(_host, 1)
	assert_signal_not_emitted(_health, "damaged")


func test_heal_increases_health() -> void:
	_health.take_damage(_host, 3)
	_health.heal(_host, 2)
	assert_eq(_host.local_state.get(&"health"), 4)


func test_heal_does_not_exceed_max() -> void:
	_health.take_damage(_host, 1)
	_health.heal(_host, 100)
	assert_eq(_host.local_state.get(&"health"), 5)


func test_heal_emits_healed_signal() -> void:
	_health.take_damage(_host, 2)
	watch_signals(_health)
	_health.heal(_host, 1)
	assert_signal_emitted_with_parameters(_health, "healed", [1])


func test_invincibility_blocks_damage() -> void:
	_health.invincibility_time = 1.0
	_health.take_damage(_host, 1)
	assert_eq(_host.local_state.get(&"health"), 4)
	# Second hit during invincibility is blocked
	_health.take_damage(_host, 1)
	assert_eq(_host.local_state.get(&"health"), 4)


func test_invincibility_expires_after_time() -> void:
	_health.invincibility_time = 0.5
	_health.take_damage(_host, 1)
	assert_eq(_host.local_state.get(&"health"), 4)
	# Simulate time passing
	_health.on_physics(_host, 0.5)
	# Now damage should apply
	_health.take_damage(_host, 1)
	assert_eq(_host.local_state.get(&"health"), 3)


func test_invincible_local_state_during_timer() -> void:
	_health.invincibility_time = 1.0
	_health.take_damage(_host, 1)
	_health.on_physics(_host, 0.1)
	assert_true(_host.local_state.get(&"invincible"))
	_health.on_physics(_host, 1.0)
	assert_false(_host.local_state.get(&"invincible"))
