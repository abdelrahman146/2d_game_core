@tool
extends EditorPlugin

const ICON := "res://icon.svg"

const CUSTOM_TYPES := [
	# Core
	{&"name": "GCBootstrap", &"base": "Node", &"script": "res://addons/game_core/core/gc_bootstrap.gd"},
	{&"name": "GCHitStop", &"base": "Node", &"script": "res://addons/game_core/core/gc_hit_stop.gd"},
	# Actors
	{&"name": "GCCharacterHost2D", &"base": "CharacterBody2D", &"script": "res://addons/game_core/actors/gc_character_host.gd"},
	{&"name": "GCRigidHost2D", &"base": "RigidBody2D", &"script": "res://addons/game_core/actors/gc_rigid_host.gd"},
	{&"name": "GCStaticHost2D", &"base": "StaticBody2D", &"script": "res://addons/game_core/actors/gc_static_host.gd"},
	{&"name": "GCAreaHost2D", &"base": "Area2D", &"script": "res://addons/game_core/actors/gc_area_host.gd"},
	# Behaviors
	{&"name": "GCBehavior", &"base": "Node", &"script": "res://addons/game_core/actors/gc_behavior.gd"},
	{&"name": "GCGravity", &"base": "Node", &"script": "res://addons/game_core/behaviors/movement/gc_gravity.gd"},
	{&"name": "GCSimpleMovement", &"base": "Node", &"script": "res://addons/game_core/behaviors/movement/gc_simple_movement.gd"},
	{&"name": "GCPatrolBehavior", &"base": "Node", &"script": "res://addons/game_core/behaviors/movement/gc_patrol_behavior.gd"},
	{&"name": "GCFollowTarget", &"base": "Node", &"script": "res://addons/game_core/behaviors/movement/gc_follow_target.gd"},
	{&"name": "GCWander", &"base": "Node", &"script": "res://addons/game_core/behaviors/movement/gc_wander.gd"},
	{&"name": "GCPlatformMovement", &"base": "Node", &"script": "res://addons/game_core/behaviors/movement/gc_platform_movement.gd"},
	{&"name": "GCEdgeSensor", &"base": "Node", &"script": "res://addons/game_core/behaviors/sensing/gc_edge_sensor.gd"},
	{&"name": "GCWallSensor", &"base": "Node", &"script": "res://addons/game_core/behaviors/sensing/gc_wall_sensor.gd"},
	{&"name": "GCDetectTarget", &"base": "Node", &"script": "res://addons/game_core/behaviors/sensing/gc_detect_target.gd"},
	{&"name": "GCLineSight", &"base": "Node", &"script": "res://addons/game_core/behaviors/sensing/gc_line_sight.gd"},
	{&"name": "GCHealth", &"base": "Node", &"script": "res://addons/game_core/behaviors/combat/gc_health.gd"},
	{&"name": "GCDamage", &"base": "Node", &"script": "res://addons/game_core/behaviors/combat/gc_damage.gd"},
	{&"name": "GCShoot", &"base": "Node", &"script": "res://addons/game_core/behaviors/combat/gc_shoot.gd"},
	{&"name": "GCDrop", &"base": "Node", &"script": "res://addons/game_core/behaviors/combat/gc_drop.gd"},
	{&"name": "GCKnockback", &"base": "Node", &"script": "res://addons/game_core/behaviors/combat/gc_knockback.gd"},
	{&"name": "GCCollectible", &"base": "Node", &"script": "res://addons/game_core/behaviors/interaction/gc_collectible.gd"},
	{&"name": "GCInteractable", &"base": "Node", &"script": "res://addons/game_core/behaviors/interaction/gc_interactable.gd"},
	{&"name": "GCSpawner", &"base": "Node", &"script": "res://addons/game_core/behaviors/interaction/gc_spawner.gd"},
	{&"name": "GCDestroyOnHit", &"base": "Node", &"script": "res://addons/game_core/behaviors/interaction/gc_destroy_on_hit.gd"},
	{&"name": "GCFacing", &"base": "Node", &"script": "res://addons/game_core/behaviors/presentation/gc_facing.gd"},
	{&"name": "GCFlashOnHit", &"base": "Node", &"script": "res://addons/game_core/behaviors/presentation/gc_flash_on_hit.gd"},
	{&"name": "GCAnimationBehavior", &"base": "Node", &"script": "res://addons/game_core/behaviors/presentation/gc_animation_behavior.gd"},
	{&"name": "GCAnimatedSpriteBehavior", &"base": "Node", &"script": "res://addons/game_core/behaviors/presentation/gc_animated_sprite_behavior.gd"},
	# Screens
	{&"name": "GCScreenRouter", &"base": "CanvasLayer", &"script": "res://addons/game_core/screens/gc_screen_router.gd"},
	{&"name": "GCScreen", &"base": "Node", &"script": "res://addons/game_core/screens/gc_screen.gd"},
	{&"name": "GCHudLayer", &"base": "CanvasLayer", &"script": "res://addons/game_core/screens/gc_hud_layer.gd"},
	# World
	{&"name": "GCWorldController", &"base": "Node", &"script": "res://addons/game_core/world/gc_world_controller.gd"},
	{&"name": "GCCamera2D", &"base": "Camera2D", &"script": "res://addons/game_core/world/gc_camera.gd"},
	{&"name": "GCScrollDriver", &"base": "Node", &"script": "res://addons/game_core/world/gc_scroll_driver.gd"},
	# Input
	{&"name": "GCVirtualJoystick", &"base": "Control", &"script": "res://addons/game_core/input/gc_virtual_joystick.gd"},
]

const CUSTOM_RESOURCES := [
	{&"name": "GCScreenDef", &"base": "Resource", &"script": "res://addons/game_core/screens/gc_screen_def.gd"},
	{&"name": "GCTransition", &"base": "Resource", &"script": "res://addons/game_core/screens/transitions/gc_transition.gd"},
	{&"name": "GCFadeTransition", &"base": "Resource", &"script": "res://addons/game_core/screens/transitions/gc_fade_transition.gd"},
	{&"name": "GCSlideTransition", &"base": "Resource", &"script": "res://addons/game_core/screens/transitions/gc_slide_transition.gd"},
	{&"name": "GCWorldSource", &"base": "Resource", &"script": "res://addons/game_core/world/gc_world_source.gd"},
	{&"name": "GCSingleSceneSource", &"base": "Resource", &"script": "res://addons/game_core/world/gc_single_scene_source.gd"},
	{&"name": "GCLevelSource", &"base": "Resource", &"script": "res://addons/game_core/world/gc_level_source.gd"},
	{&"name": "GCChunkSource", &"base": "Resource", &"script": "res://addons/game_core/world/gc_chunk_source.gd"},
	{&"name": "GCStreamChunkSource", &"base": "Resource", &"script": "res://addons/game_core/world/gc_stream_chunk_source.gd"},
	{&"name": "GCChunkSelector", &"base": "Resource", &"script": "res://addons/game_core/world/gc_chunk_selector.gd"},
	{&"name": "GCStatsData", &"base": "Resource", &"script": "res://addons/game_core/resources/gc_stats_data.gd"},
	{&"name": "GCLootTable", &"base": "Resource", &"script": "res://addons/game_core/resources/gc_loot_table.gd"},
	{&"name": "GCAnimationBinding", &"base": "Resource", &"script": "res://addons/game_core/resources/gc_animation_binding.gd"},
	{&"name": "GCLevelData", &"base": "Resource", &"script": "res://addons/game_core/resources/gc_level_data.gd"},
	{&"name": "GCChunkData", &"base": "Resource", &"script": "res://addons/game_core/resources/gc_chunk_data.gd"},
]


func _enter_tree() -> void:
	var icon := load(ICON) if FileAccess.file_exists(ICON) else null
	for t in CUSTOM_TYPES:
		add_custom_type(t.name, t.base, load(t.script), icon)
	for t in CUSTOM_RESOURCES:
		add_custom_type(t.name, t.base, load(t.script), icon)


func _exit_tree() -> void:
	for t in CUSTOM_TYPES:
		remove_custom_type(t.name)
	for t in CUSTOM_RESOURCES:
		remove_custom_type(t.name)
