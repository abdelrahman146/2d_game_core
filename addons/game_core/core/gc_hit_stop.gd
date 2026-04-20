extends Node
class_name GCHitStop
## Brief time-freeze effect (hit-stop / freeze frame).
## Place anywhere in the scene tree. Call freeze() to trigger a dramatic pause.
##
## Uses Engine.time_scale so all physics, animations, and timers pause together.
## A real-time SceneTreeTimer restores normal speed after the duration.

signal freeze_started
signal freeze_ended

## Default freeze duration in seconds when calling freeze() with no argument.
@export var default_duration := 0.05

var _is_frozen := false


## Freeze the game for the given duration (seconds).
## If already frozen, restarts with the longer remaining duration.
func freeze(duration := -1.0) -> void:
	var d := duration if duration > 0.0 else default_duration
	if d <= 0.0:
		return
	if not _is_frozen:
		_is_frozen = true
		freeze_started.emit()
	Engine.time_scale = 0.0
	# Create a real-time timer that ignores time_scale
	var timer := get_tree().create_timer(d, true, false, true)
	await timer.timeout
	_unfreeze()


func _unfreeze() -> void:
	if not _is_frozen:
		return
	_is_frozen = false
	Engine.time_scale = 1.0
	freeze_ended.emit()
