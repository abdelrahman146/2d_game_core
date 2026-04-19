extends Resource
class_name GCScreenTransition

const GCScreenBase = preload("res://addons/game_core/screens/gc_screen_base.gd")
const GCScreenRouter = preload("res://addons/game_core/screens/gc_screen_router.gd")


func begin(router: Object, from_screen: GCScreenBase, to_screen: GCScreenBase, payload: Dictionary = {}) -> void:
	router.complete_transition(from_screen, to_screen, payload)
