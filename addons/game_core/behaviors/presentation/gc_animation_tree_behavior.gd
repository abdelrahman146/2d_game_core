extends "res://addons/game_core/behaviors/presentation/gc_animation_playback_base.gd"
class_name GCAnimationTreeBehavior
## Drives an AnimationTree (root state machine) from the shared animation
## local_state contract: animation_state / animation_trigger / animation_queue.
##
## Use this when your character needs blending or a complex state machine.
## Set `state_machine_path` to the parameters path of the root state machine
## inside the AnimationTree (default: "parameters/playback"). The behavior
## calls `travel(state)` for state changes and `start(trigger)` for triggers,
## matching how Godot's AnimationNodeStateMachinePlayback works.

@export var animation_tree_path: NodePath
## Path within the AnimationTree to the AnimationNodeStateMachinePlayback.
## Default matches the typical setup: a state machine at the tree root.
@export var state_machine_path: String = "parameters/playback"

var _tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback


func on_host_ready(host: Node) -> void:
	_setup_animation_contract()
	_tree = _resolve_tree(host)
	if _tree == null:
		return
	_tree.active = true
	_playback = _tree.get(state_machine_path) as AnimationNodeStateMachinePlayback


func on_physics(host: Node, _delta: float) -> void:
	if _tree == null or _playback == null:
		return
	_update_animation(host)


func _has_animation(anim_name: StringName) -> bool:
	if _playback == null:
		return false
	# AnimationTree state machines do not expose a public "has_node"; the
	# safest portable check is to ask the tree's tree_root if it's a state
	# machine. We treat any non-empty name as resolvable and let travel()
	# silently no-op if the state does not exist.
	return not anim_name.is_empty()


func _get_current_animation_name() -> StringName:
	if _playback == null:
		return &""
	return StringName(_playback.get_current_node())


func _is_playing() -> bool:
	return _playback != null and _playback.is_playing()


func _play_animation(anim_name: StringName, restart_if_same: bool) -> void:
	if _playback == null:
		return
	# `start` resets time; `travel` honors transitions. Use `start` only when
	# explicitly restarting the same state (trigger semantics).
	if restart_if_same and StringName(_playback.get_current_node()) == anim_name:
		_playback.start(anim_name)
	else:
		_playback.travel(anim_name)


func _set_speed_scale(speed_scale: float) -> void:
	if _tree == null:
		return
	# Common convention: parameters/TimeScale/scale on a TimeScale node.
	# If absent, no-op.
	if _tree.has_method(&"set"):
		_tree.set("parameters/TimeScale/scale", speed_scale)


func _resolve_tree(host: Node) -> AnimationTree:
	if not animation_tree_path.is_empty():
		var node := host.get_node_or_null(animation_tree_path)
		if node is AnimationTree:
			return node as AnimationTree
	for child in host.get_children():
		if child is AnimationTree:
			return child as AnimationTree
	return null
