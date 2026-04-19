extends Resource
class_name GCScreenDef
## Defines a screen: its id, scene, and optional transition.

const _Transition = preload("res://addons/game_core/screens/transitions/gc_transition.gd")

@export var id: StringName
@export var scene: PackedScene
@export var transition: _Transition
@export var is_persistent := false
