extends GutTest
## Tests for the animation contract across AnimationPlayer, Sprite2D, and AnimatedSprite2D.

const GCCharacterHost2D = preload("res://addons/game_core/actors/gc_character_host.gd")
const GCAnimationBinding = preload("res://addons/game_core/resources/gc_animation_binding.gd")
const GCAnimationBehavior = preload("res://addons/game_core/behaviors/presentation/gc_animation_behavior.gd")
const GCAnimatedSpriteBehavior = preload("res://addons/game_core/behaviors/presentation/gc_animated_sprite_behavior.gd")
const GCFacing = preload("res://addons/game_core/behaviors/presentation/gc_facing.gd")
const GCFlashOnHit = preload("res://addons/game_core/behaviors/presentation/gc_flash_on_hit.gd")
const GCHealth = preload("res://addons/game_core/behaviors/combat/gc_health.gd")
const GCDestroyOnHit = preload("res://addons/game_core/behaviors/interaction/gc_destroy_on_hit.gd")


func _make_host(children: Array[Node]) -> GCCharacterHost2D:
	var host := GCCharacterHost2D.new()
	for child in children:
		host.add_child(child)
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)
	return host


func _make_animation_player(names: Array = [&"idle", &"wall_slide", &"swim", &"attack_heavy_anim", &"dance_anim"]) -> AnimationPlayer:
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for name in names:
		var animation := Animation.new()
		animation.length = 0.5
		library.add_animation(name, animation)
	player.add_animation_library(&"", library)
	return player


func _make_animated_sprite(names: Array = [&"idle", &"wall_slide", &"swim", &"attack_heavy_anim", &"hurt_anim"]) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	for name in names:
		frames.add_animation(name)
		frames.add_frame(name, texture)
	sprite.sprite_frames = frames
	return sprite


func _make_binding(id: StringName, animation: StringName) -> GCAnimationBinding:
	var binding := GCAnimationBinding.new()
	binding.id = id
	binding.animation = animation
	return autofree(binding) as GCAnimationBinding


func test_animation_behavior_plays_arbitrary_state_name() -> void:
	var player := _make_animation_player()
	var behavior := GCAnimationBehavior.new()
	var host := _make_host([player, behavior])
	host.local_state[&"animation_state"] = &"wall_slide"
	host._physics_process(0.016)
	player.advance(0.0)
	assert_eq(player.current_animation, &"wall_slide")


func test_animation_behavior_uses_trigger_and_queue_before_state() -> void:
	var player := _make_animation_player()
	var behavior := GCAnimationBehavior.new()
	behavior.bindings = [
		_make_binding(&"attack_heavy", &"attack_heavy_anim"),
		_make_binding(&"celebrate", &"dance_anim"),
	]
	var host := _make_host([player, behavior])
	host.local_state[&"animation_state"] = &"wall_slide"
	host.local_state[&"animation_trigger"] = &"attack_heavy"
	host.local_state[&"animation_queue"] = [&"celebrate"]
	host._physics_process(0.016)
	player.advance(0.0)
	assert_eq(player.current_animation, &"attack_heavy_anim")
	assert_false(host.local_state.has(&"animation_trigger"))
	player.stop()
	host._physics_process(0.016)
	player.advance(0.0)
	assert_eq(player.current_animation, &"dance_anim")
	assert_false(host.local_state.has(&"animation_queue"))
	player.stop()
	host._physics_process(0.016)
	player.advance(0.0)
	assert_eq(player.current_animation, &"wall_slide")


func test_animation_behavior_applies_speed_scale() -> void:
	var player := _make_animation_player()
	var behavior := GCAnimationBehavior.new()
	var host := _make_host([player, behavior])
	host.local_state[&"animation_state"] = &"idle"
	host.local_state[&"animation_speed_scale"] = 1.75
	host._physics_process(0.016)
	assert_eq(player.speed_scale, 1.75)


func test_animated_sprite_behavior_plays_arbitrary_state_name() -> void:
	var sprite := _make_animated_sprite()
	var behavior := GCAnimatedSpriteBehavior.new()
	var host := _make_host([sprite, behavior])
	host.local_state[&"animation_state"] = &"swim"
	host._physics_process(0.016)
	assert_eq(sprite.animation, &"swim")


func test_animated_sprite_behavior_uses_bindings_for_trigger_then_returns_to_state() -> void:
	var sprite := _make_animated_sprite()
	var behavior := GCAnimatedSpriteBehavior.new()
	behavior.bindings = [_make_binding(&"hurt", &"hurt_anim")]
	var host := _make_host([sprite, behavior])
	host.local_state[&"animation_state"] = &"wall_slide"
	host.local_state[&"animation_trigger"] = &"hurt"
	host._physics_process(0.016)
	assert_eq(sprite.animation, &"hurt_anim")
	assert_false(host.local_state.has(&"animation_trigger"))
	sprite.stop()
	host._physics_process(0.016)
	assert_eq(sprite.animation, &"wall_slide")


func test_animated_sprite_behavior_applies_speed_scale() -> void:
	var sprite := _make_animated_sprite()
	var behavior := GCAnimatedSpriteBehavior.new()
	var host := _make_host([sprite, behavior])
	host.local_state[&"animation_state"] = &"idle"
	host.local_state[&"animation_speed_scale"] = 0.5
	host._physics_process(0.016)
	assert_eq(sprite.speed_scale, 0.5)


func test_facing_flips_sprite2d() -> void:
	var sprite := Sprite2D.new()
	var behavior := GCFacing.new()
	var host := _make_host([sprite, behavior])
	host.local_state[&"facing_direction"] = -1
	host._physics_process(0.016)
	assert_true(sprite.flip_h)


func test_facing_flips_animated_sprite2d() -> void:
	var sprite := _make_animated_sprite()
	var behavior := GCFacing.new()
	var host := _make_host([sprite, behavior])
	host.local_state[&"facing_direction"] = -1
	host._physics_process(0.016)
	assert_true(sprite.flip_h)


func test_flash_on_hit_flashes_animated_sprite2d() -> void:
	var sprite := _make_animated_sprite()
	sprite.modulate = Color(0.8, 0.8, 1.0, 1.0)
	var health := GCHealth.new()
	var flash := GCFlashOnHit.new()
	flash.flash_color = Color.RED
	flash.flash_duration = 0.04
	flash.flash_count = 1
	var host := _make_host([sprite, health, flash])
	var original := sprite.modulate
	health.take_damage(host, 1)
	await get_tree().create_timer(0.01).timeout
	assert_ne(sprite.modulate, original)
	await get_tree().create_timer(0.05).timeout
	assert_eq(sprite.modulate, original)


func test_destroy_on_hit_requests_animation_trigger() -> void:
	var health := GCHealth.new()
	var destroy_on_hit := GCDestroyOnHit.new()
	destroy_on_hit.play_animation = "death"
	var host := _make_host([health, destroy_on_hit])
	health.take_damage(host, 3)
	assert_eq(host.local_state.get(&"animation_trigger"), &"death")
