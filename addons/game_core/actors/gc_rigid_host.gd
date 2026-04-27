extends RigidBody2D
class_name GCRigidHost2D
## Actor host for physics-driven objects: crates, balls, throwables, ragdolls.
## Add GCBehavior children to compose physics interactions.

const _Behavior = preload("res://addons/game_core/actors/gc_behavior.gd")

## Optional GCStatsData resource. Use Godot's native scene-tree groups
## (Inspector → Node → Groups, or `add_to_group(...)`) for tagging and
## category lookups
@export var stats: Resource

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
