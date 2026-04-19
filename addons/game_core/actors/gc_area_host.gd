extends Area2D
class_name GCAreaHost2D
## Actor host for areas: triggers, pickups, damage zones, detection regions, collectibles.
## Add GCBehavior children to compose reactions to overlaps and signals.

const _Behavior = preload("res://addons/game_core/actors/gc_behavior.gd")

@export var entity_tags: PackedStringArray = []
@export var stats: Resource  ## Optional GCStatsData resource

var local_state: Dictionary = {}
var _behaviors: Array[_Behavior] = []


func _ready() -> void:
	_collect_behaviors()
	for b in _behaviors:
		b.on_host_ready(self)


func _process(delta: float) -> void:
	for b in _behaviors:
		if b.enabled:
			b.on_process(self, delta)


func _physics_process(delta: float) -> void:
	for b in _behaviors:
		if b.enabled:
			b.on_physics(self, delta)


func _exit_tree() -> void:
	for i in range(_behaviors.size() - 1, -1, -1):
		_behaviors[i].on_host_destroyed(self)


func get_behavior(type: Script) -> _Behavior:
	for b in _behaviors:
		if b.get_script() == type:
			return b
	return null


func has_tag(tag: StringName) -> bool:
	return entity_tags.has(tag)


func find_child_of_type(type: Variant) -> Node:
	for child in get_children():
		if is_instance_of(child, type):
			return child
	return null


func _collect_behaviors() -> void:
	var by_phase: Array[Array] = [[], [], [], []]
	for child in get_children():
		if child is _Behavior:
			by_phase[child.phase].append(child)
	_behaviors.clear()
	for group in by_phase:
		_behaviors.append_array(group)
