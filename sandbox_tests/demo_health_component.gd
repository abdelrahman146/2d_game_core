extends "res://addons/game_core/entities/gc_entity_component.gd"
class_name DemoHealthComponent

@export var max_health := 3


func build_state() -> Dictionary:
	return {
		&"health": max_health,
		&"max_health": max_health,
	}


func on_entity_created(entity: GCEntityRuntime, _context: GCGameContext) -> void:
	entity.set_value(&"is_alive", true)
