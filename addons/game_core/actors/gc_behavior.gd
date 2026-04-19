extends Node
class_name GCBehavior
## Base class for all behavior components.
## Add as a child of any actor host node. The host dispatches lifecycle hooks.
##
## Override any hook you need:
##   on_host_ready(host)
##   on_process(host, delta)
##   on_physics(host, delta)
##   on_host_destroyed(host)

enum Phase { SENSE, DECIDE, ACT, PRESENT }

## Execution phase. Behaviors run in phase order, then tree order within a phase.
@export var phase: Phase = Phase.ACT

## If false, this behavior is skipped during dispatch.
@export var enabled := true


func on_host_ready(_host: Node) -> void:
	pass


func on_process(_host: Node, _delta: float) -> void:
	pass


func on_physics(_host: Node, _delta: float) -> void:
	pass


func on_host_destroyed(_host: Node) -> void:
	pass
