extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCInteractable
## Makes the host interactable (press a button near it to trigger).
## Filtering is done by the interact Area2D's collision_mask — set it to
## only see the layer of bodies that may interact (typically the player).
## Emits `interacted` when an in-range body presses the action.

signal interacted(interactor: Node)
signal interact_available(interactor: Node)
signal interact_unavailable

@export var interact_action: StringName = &"interact"
@export var interact_area_path: NodePath
@export var one_time := false

var _interactor: Node = null
var _used := false
var _area: Area2D


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	_area = _get_area(host)
	if _area:
		_area.body_entered.connect(_on_body_entered)
		_area.body_exited.connect(_on_body_exited)


func on_process(_host: Node, _delta: float) -> void:
	if _interactor == null:
		return
	if one_time and _used:
		return
	if Input.is_action_just_pressed(interact_action):
		_used = true
		interacted.emit(_interactor)


func _on_body_entered(body: Node) -> void:
	_interactor = body
	interact_available.emit(body)


func _on_body_exited(body: Node) -> void:
	if body == _interactor:
		_interactor = null
		interact_unavailable.emit()


func _get_area(host: Node) -> Area2D:
	if not interact_area_path.is_empty():
		var node := host.get_node_or_null(interact_area_path)
		if node is Area2D:
			return node as Area2D
	if host is Area2D:
		return host as Area2D
	for child in host.get_children():
		if child is Area2D and (child.name == "InteractArea" or child.name == "InteractionArea"):
			return child as Area2D
	return null
