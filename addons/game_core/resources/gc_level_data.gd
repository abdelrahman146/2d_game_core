extends Resource
class_name GCLevelData
## Describes a single level for the level-based world source.

@export var level_id: StringName
@export var display_name: String = ""
@export var scene: PackedScene
@export var is_unlocked := true
@export var metadata: Dictionary = {}
