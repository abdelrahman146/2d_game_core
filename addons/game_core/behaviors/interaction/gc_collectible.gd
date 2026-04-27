extends "res://addons/game_core/actors/gc_behavior.gd"
class_name GCCollectible
## Makes the host collectible. Filtering is done by the host (or pickup)
## Area2D's collision_mask — set it to only see the collector layer.
## Emits `collected` and optionally destroys the host.

signal collected(collector: Node, reward_data: Dictionary)

@export var reward_type: StringName = &"coin"
@export var reward_amount := 1
@export var destroy_on_collect := true

var _collected := false


func _init() -> void:
	phase = Phase.ACT


func on_host_ready(host: Node) -> void:
	if host is Area2D:
		(host as Area2D).body_entered.connect(_on_body_entered.bind(host))
	else:
		# Look for a child Area2D
		for child in host.get_children():
			if child is Area2D and (child.name == "CollectArea" or child.name == "PickupArea"):
				(child as Area2D).body_entered.connect(_on_body_entered.bind(host))
				break


func _on_body_entered(body: Node, host: Node) -> void:
	if _collected:
		return
	_collected = true
	var data := {&"type": reward_type, &"amount": reward_amount}
	collected.emit(body, data)
	if destroy_on_collect:
		host.queue_free()
