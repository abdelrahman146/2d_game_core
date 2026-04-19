@tool
extends EditorPlugin

const CORE_ICON := "res://icon.svg"

const CUSTOM_TYPES := [
	{
		"name": "GCGameCore",
		"base": "Node",
		"script": "res://addons/game_core/core/gc_game_core.gd",
	},
	{
		"name": "GCScreenRouter",
		"base": "Node",
		"script": "res://addons/game_core/screens/gc_screen_router.gd",
	},
	{
		"name": "GCScreenBase",
		"base": "Node",
		"script": "res://addons/game_core/screens/gc_screen_base.gd",
	},
	{
		"name": "GCWorldController",
		"base": "Node",
		"script": "res://addons/game_core/world/gc_world_controller.gd",
	},
	{
		"name": "GCEntityDefinition",
		"base": "Resource",
		"script": "res://addons/game_core/entities/gc_entity_definition.gd",
	},
	{
		"name": "GCEntityComponent",
		"base": "Resource",
		"script": "res://addons/game_core/entities/gc_entity_component.gd",
	},
	{
		"name": "GCInteraction",
		"base": "Resource",
		"script": "res://addons/game_core/interactions/gc_interaction.gd",
	},
	{
		"name": "GCScreenDefinition",
		"base": "Resource",
		"script": "res://addons/game_core/screens/gc_screen_definition.gd",
	},
	{
		"name": "GCScreenTransition",
		"base": "Resource",
		"script": "res://addons/game_core/screens/gc_screen_transition.gd",
	},
	{
		"name": "GCWorldSource",
		"base": "Resource",
		"script": "res://addons/game_core/world/gc_world_source.gd",
	},
]


func _enter_tree() -> void:
	var icon := load(CORE_ICON)
	for type_data in CUSTOM_TYPES:
		add_custom_type(type_data.name, type_data.base, load(type_data.script), icon)


func _exit_tree() -> void:
	for type_data in CUSTOM_TYPES:
		remove_custom_type(type_data.name)
