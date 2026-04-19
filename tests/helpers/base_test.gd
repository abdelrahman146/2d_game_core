extends GutTest
## Shared helpers for game_core tests.
## IMPORTANT: All hosts added to the tree MUST have processing disabled to
## prevent the engine from running behavior dispatch loops during tests.


## Creates a CharacterBody2D host, adds it to the tree (triggering _ready),
## then disables engine processing so behaviors only run when manually called.
func create_character_host() -> GCCharacterHost2D:
	var host := GCCharacterHost2D.new()
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)
	return host


## Creates an Area2D host, adds it to the tree (triggering _ready),
## then disables engine processing.
func create_area_host() -> GCAreaHost2D:
	var host := GCAreaHost2D.new()
	add_child_autoqfree(host)
	host.set_process(false)
	host.set_physics_process(false)
	return host


## Creates a GCGameContext with autofree cleanup.
func create_context() -> GCGameContext:
	var ctx := GCGameContext.new()
	return autofree(ctx) as GCGameContext
