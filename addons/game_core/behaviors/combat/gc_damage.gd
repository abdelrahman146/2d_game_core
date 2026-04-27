extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCDamage
## Deals damage on contact via Area2D overlap.
##
## Filtering is done by the Area2D's collision_mask — set the mask in the
## inspector to only see physics layers that should take damage. Targets
## must have a GCHealth child behavior to actually take damage.

const _Health = preload("res://addons/game_core/behaviors/combat/gc_health.gd")

signal damage_dealt(target: Node, amount: int)

@export var damage := 1
@export var damage_area_path: NodePath
@export var one_shot := false  ## If true, only damages once then disables

var _has_hit := false
var _area: Area2D


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	_area = _get_area(host)
	if _area:
		_area.body_entered.connect(_on_body_entered.bind(host))
		_area.area_entered.connect(_on_area_entered.bind(host))


func _on_body_entered(body: Node, _host: Node) -> void:
	if one_shot and _has_hit:
		return
	_try_damage(body)


func _on_area_entered(area: Area2D, _host: Node) -> void:
	if one_shot and _has_hit:
		return
	var target := area.get_parent()
	_try_damage(target)


func _try_damage(target: Node) -> void:
	var health_behavior: _Health = _find_health(target)
	if health_behavior:
		health_behavior.take_damage(target, damage, get_parent())
		damage_dealt.emit(target, damage)
		_has_hit = true


func _find_health(node: Node) -> _Health:
	for child in node.get_children():
		if child is _Health:
			return child as _Health
	return null


func _get_area(host: Node) -> Area2D:
	if not damage_area_path.is_empty():
		var node := host.get_node_or_null(damage_area_path)
		if node is Area2D:
			return node as Area2D
	for child in host.get_children():
		if child is Area2D and (child.name == "DamageArea" or child.name == "HitArea" or child.name == "Hitbox"):
			return child as Area2D
	return null
