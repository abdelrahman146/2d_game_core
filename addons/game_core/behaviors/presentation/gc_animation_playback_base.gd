extends "res://addons/game_core/actors/gc_behavior.gd"
## Shared playback contract for renderer-specific animation behaviors.
## Behaviors write animation_state / animation_trigger / animation_queue into
## host.local_state, and subclasses render the resolved animation names.

@export var state_key: StringName = &"animation_state"
@export var trigger_key: StringName = &"animation_trigger"
@export var queue_key: StringName = &"animation_queue"
@export var speed_scale_key: StringName = &"animation_speed_scale"
@export var default_state: StringName
@export var use_state_names_as_animation_names := true
@export var lock_trigger_until_finished := true
@export var restart_trigger_if_same := true
@export var bindings: Array[GCAnimationBinding] = []

var _active_trigger: StringName
var _bindings_by_id: Dictionary = {}


func _init() -> void:
	phase = Phase.PRESENT


func _setup_animation_contract() -> void:
	_active_trigger = &""
	_bindings_by_id.clear()
	for binding in bindings:
		if binding == null or binding.id.is_empty():
			continue
		_bindings_by_id[binding.id] = binding.animation if not binding.animation.is_empty() else binding.id


func _update_animation(host: Node) -> void:
	_apply_speed_scale(host)

	if not _active_trigger.is_empty() and _is_active_trigger_running():
		if lock_trigger_until_finished:
			return
	else:
		_active_trigger = &""

	var trigger := _consume_trigger(host)
	if not trigger.is_empty():
		var trigger_animation := _resolve_animation_name(trigger)
		if _play_resolved_animation(trigger_animation, restart_trigger_if_same):
			_active_trigger = trigger_animation
			return

	var state := _read_state(host)
	if state.is_empty():
		return
	_play_resolved_animation(_resolve_animation_name(state), false)


func _resolve_animation_name(id: StringName) -> StringName:
	if id.is_empty():
		return &""
	if _bindings_by_id.has(id):
		return _bindings_by_id[id] as StringName
	return id if use_state_names_as_animation_names else &""


func _read_state(host: Node) -> StringName:
	var raw_value: Variant = default_state
	if not state_key.is_empty():
		raw_value = host.local_state.get(state_key, default_state)
	var state := _coerce_name(raw_value)
	if state.is_empty():
		return default_state
	return state


func _consume_trigger(host: Node) -> StringName:
	var direct := _consume_direct_trigger(host)
	if not direct.is_empty():
		return direct
	return _consume_queued_trigger(host)


func _consume_direct_trigger(host: Node) -> StringName:
	if trigger_key.is_empty() or not host.local_state.has(trigger_key):
		return &""
	var trigger := _coerce_name(host.local_state[trigger_key])
	host.local_state.erase(trigger_key)
	return trigger


func _consume_queued_trigger(host: Node) -> StringName:
	if queue_key.is_empty() or not host.local_state.has(queue_key):
		return &""
	var queue_value: Variant = host.local_state[queue_key]
	if not (queue_value is Array):
		return &""

	var queue: Array = (queue_value as Array).duplicate()
	while not queue.is_empty():
		var next_value: Variant = queue[0]
		queue.remove_at(0)
		if queue.is_empty():
			host.local_state.erase(queue_key)
		else:
			host.local_state[queue_key] = queue

		var trigger := _coerce_name(next_value)
		if not trigger.is_empty():
			return trigger

	return &""


func _apply_speed_scale(host: Node) -> void:
	if speed_scale_key.is_empty() or not host.local_state.has(speed_scale_key):
		return
	var scale_value: Variant = host.local_state[speed_scale_key]
	if scale_value is float or scale_value is int:
		_set_speed_scale(float(scale_value))


func _coerce_name(value: Variant) -> StringName:
	if value is StringName:
		return value as StringName
	if value is String and not (value as String).is_empty():
		return StringName(value)
	return &""


func _play_resolved_animation(anim_name: StringName, restart_if_same: bool) -> bool:
	if anim_name.is_empty() or not _has_animation(anim_name):
		return false
	var is_same_animation := _get_current_animation_name() == anim_name
	if is_same_animation and _is_playing() and not restart_if_same:
		return true
	_play_animation(anim_name, restart_if_same and is_same_animation)
	return true


func _is_active_trigger_running() -> bool:
	if _active_trigger.is_empty():
		return false
	if _get_current_animation_name() != _active_trigger:
		return false
	return _is_playing()


func _has_animation(_anim_name: StringName) -> bool:
	return false


func _get_current_animation_name() -> StringName:
	return &""


func _is_playing() -> bool:
	return false


func _play_animation(_anim_name: StringName, _restart_if_same: bool) -> void:
	pass


func _set_speed_scale(_speed_scale: float) -> void:
	pass
