extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCChargedBeam
## Runs a charged beam attack with windup, active, and cooldown phases.
## Writes beam state to local_state and can toggle a visual root and hitbox node.

enum TriggerMode { TARGET_DETECTED, TIMER }
enum AimMode { FIXED_DIRECTION, TARGET_NODE, TARGET_POSITION, FACING_DIRECTION }
enum BeamPhase { IDLE, WINDUP, ACTIVE, COOLDOWN }

signal beam_windup_started(direction: Vector2)
signal beam_activated(direction: Vector2)
signal beam_finished

@export var auto_fire := true
@export var trigger_mode: TriggerMode = TriggerMode.TARGET_DETECTED
@export var aim_mode: AimMode = AimMode.FIXED_DIRECTION
@export var windup_time := 0.6
@export var active_time := 0.35
@export var cooldown := 1.25
@export var fixed_direction := Vector2.DOWN
@export var track_target_during_windup := true
@export var track_target_during_active := false
@export var update_length_during_windup := true
@export var update_length_during_active := true
@export var gate_state_key: StringName = &""
@export var gate_state_value := true
@export var target_key: StringName = &"target_node"
@export var position_key: StringName = &"target_position"
@export var state_key: StringName = &"beam_state"
@export var active_key: StringName = &"beam_active"
@export var direction_key: StringName = &"beam_direction"
@export var angle_key: StringName = &"beam_rotation"
@export var length_key: StringName = &"beam_length"
@export var hit_position_key: StringName = &"beam_hit_position"
@export var default_length := 256.0
@export var max_range := 2048.0
@export var beam_root_path: NodePath
@export var beam_collision_path: NodePath
@export var length_raycast_path: NodePath

var _phase_state: BeamPhase = BeamPhase.IDLE
var _timer := 0.0
var _locked_direction := Vector2.DOWN
var _beam_root: Node
var _beam_collision: Node
var _length_raycast: RayCast2D


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	_beam_root = _resolve_node(host, beam_root_path)
	_beam_collision = _resolve_beam_collision(host)
	_length_raycast = _resolve_length_raycast(host)
	_enter_idle(host)


func on_physics(host: Node, delta: float) -> void:
	match _phase_state:
		BeamPhase.IDLE:
			if not auto_fire:
				return
			if not _passes_gate(host):
				return
			if not _can_auto_fire(host):
				return
			fire(host)
		BeamPhase.WINDUP:
			if track_target_during_windup:
				_locked_direction = _get_beam_direction(host)
				_apply_beam_transform(host)
			elif update_length_during_windup:
				_update_beam_length(host)
			_timer = maxf(_timer - delta, 0.0)
			if _timer <= 0.0:
				_enter_active(host)
		BeamPhase.ACTIVE:
			if track_target_during_active:
				_locked_direction = _get_beam_direction(host)
				_apply_beam_transform(host)
			elif update_length_during_active:
				_update_beam_length(host)
			_timer = maxf(_timer - delta, 0.0)
			if _timer <= 0.0:
				_enter_cooldown(host)
		BeamPhase.COOLDOWN:
			_timer = maxf(_timer - delta, 0.0)
			if _timer <= 0.0:
				_enter_idle(host)


func fire(host: Node) -> void:
	if _phase_state != BeamPhase.IDLE:
		return
	if not host is Node2D:
		return
	_locked_direction = _get_beam_direction(host)
	_enter_windup(host)


func get_phase_name() -> StringName:
	match _phase_state:
		BeamPhase.WINDUP:
			return &"windup"
		BeamPhase.ACTIVE:
			return &"active"
		BeamPhase.COOLDOWN:
			return &"cooldown"
	return &"idle"


func _enter_idle(host: Node) -> void:
	_phase_state = BeamPhase.IDLE
	_timer = 0.0
	host.local_state[state_key] = &"idle"
	host.local_state[active_key] = false
	host.local_state[direction_key] = _locked_direction
	host.local_state[angle_key] = _locked_direction.angle()
	host.local_state[length_key] = default_length
	host.local_state[hit_position_key] = _default_hit_position(host)
	_set_beam_root_visible(false)
	_set_beam_collision_enabled(false)


func _enter_windup(host: Node) -> void:
	_phase_state = BeamPhase.WINDUP
	_timer = maxf(windup_time, 0.0)
	host.local_state[state_key] = &"windup"
	host.local_state[active_key] = false
	_apply_beam_transform(host)
	_set_beam_root_visible(false)
	_set_beam_collision_enabled(false)
	beam_windup_started.emit(_locked_direction)
	if _timer <= 0.0:
		_enter_active(host)


func _enter_active(host: Node) -> void:
	_phase_state = BeamPhase.ACTIVE
	_timer = maxf(active_time, 0.0)
	host.local_state[state_key] = &"active"
	host.local_state[active_key] = true
	_apply_beam_transform(host)
	_set_beam_root_visible(true)
	_set_beam_collision_enabled(true)
	beam_activated.emit(_locked_direction)
	if _timer <= 0.0:
		_enter_cooldown(host)


func _enter_cooldown(host: Node) -> void:
	_phase_state = BeamPhase.COOLDOWN
	_timer = maxf(cooldown, 0.0)
	host.local_state[state_key] = &"cooldown"
	host.local_state[active_key] = false
	_set_beam_root_visible(false)
	_set_beam_collision_enabled(false)
	beam_finished.emit()
	if _timer <= 0.0:
		_enter_idle(host)


func _can_auto_fire(host: Node) -> bool:
	match trigger_mode:
		TriggerMode.TIMER:
			return true
		TriggerMode.TARGET_DETECTED:
			return host.local_state.get(&"target_detected", false)
	return false


func _passes_gate(host: Node) -> bool:
	if gate_state_key.is_empty():
		return true
	if not host.local_state.has(gate_state_key):
		return false
	return host.local_state[gate_state_key] == gate_state_value


func _get_beam_direction(host: Node) -> Vector2:
	var direction := fixed_direction
	match aim_mode:
		AimMode.FIXED_DIRECTION:
			direction = fixed_direction
		AimMode.TARGET_NODE:
			var target: Variant = host.local_state.get(target_key, null)
			if target is Node2D and is_instance_valid(target) and host is Node2D:
				direction = (target as Node2D).global_position - (host as Node2D).global_position
		AimMode.TARGET_POSITION:
			var target_pos: Variant = host.local_state.get(position_key, null)
			if target_pos is Vector2 and host is Node2D:
				direction = (target_pos as Vector2) - (host as Node2D).global_position
		AimMode.FACING_DIRECTION:
			var facing: int = host.local_state.get(&"facing_direction", 1)
			direction = Vector2.RIGHT * facing

	if direction == Vector2.ZERO:
		direction = fixed_direction if fixed_direction != Vector2.ZERO else Vector2.DOWN
	return direction.normalized()


func _apply_beam_transform(host: Node) -> void:
	host.local_state[direction_key] = _locked_direction
	host.local_state[angle_key] = _locked_direction.angle()
	_update_beam_length(host)
	if _beam_root is Node2D:
		(_beam_root as Node2D).rotation = _locked_direction.angle()


func _resolve_beam_collision(host: Node) -> Node:
	var resolved := _resolve_node(host, beam_collision_path)
	if resolved != null:
		return resolved
	return _beam_root


func _resolve_node(host: Node, path: NodePath) -> Node:
	if path.is_empty():
		return null
	return host.get_node_or_null(path)


func _resolve_length_raycast(host: Node) -> RayCast2D:
	if not length_raycast_path.is_empty():
		var node := host.get_node_or_null(length_raycast_path)
		if node is RayCast2D:
			return node as RayCast2D
	for child in host.get_children():
		if child is RayCast2D and (child.name == "BeamRay" or child.name == "LengthRay"):
			return child as RayCast2D
	return null


func _update_beam_length(host: Node) -> void:
	if not host is Node2D:
		host.local_state[length_key] = default_length
		return

	var host2d := host as Node2D
	var beam_length := default_length
	var hit_position := _default_hit_position(host)

	if _length_raycast != null:
		_length_raycast.global_position = host2d.global_position
		_length_raycast.rotation = _locked_direction.angle()
		_length_raycast.target_position = Vector2.RIGHT * max_range
		_length_raycast.force_raycast_update()
		if _length_raycast.is_colliding():
			hit_position = _length_raycast.get_collision_point()
			beam_length = host2d.global_position.distance_to(hit_position)
		else:
			beam_length = max_range
			hit_position = host2d.global_position + _locked_direction * max_range

	host.local_state[length_key] = beam_length
	host.local_state[hit_position_key] = hit_position


func _default_hit_position(host: Node) -> Vector2:
	if host is Node2D:
		return (host as Node2D).global_position + _locked_direction * default_length
	return _locked_direction * default_length


func _set_beam_root_visible(visible: bool) -> void:
	if _beam_root is CanvasItem:
		(_beam_root as CanvasItem).visible = visible


func _set_beam_collision_enabled(enabled: bool) -> void:
	if _beam_collision == null:
		return
	if _beam_collision is Area2D:
		(_beam_collision as Area2D).monitoring = enabled
		(_beam_collision as Area2D).monitorable = enabled
		return
	if _beam_collision is CollisionShape2D:
		(_beam_collision as CollisionShape2D).disabled = not enabled
		return
	if _beam_collision is CollisionPolygon2D:
		(_beam_collision as CollisionPolygon2D).disabled = not enabled
