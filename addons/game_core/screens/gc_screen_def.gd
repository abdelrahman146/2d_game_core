extends Resource
class_name GCScreenDef
## Defines a screen: its id, scene, and optional transition.

@export var id: StringName
@export var scene: PackedScene
@export var transition: GCTransition
@export var is_persistent := false
