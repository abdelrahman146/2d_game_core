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
var _timer: Timer


func _ready() -> void:
	_ensure_timer()


func _exit_tree() -> void:
	if _timer != null:
		_timer.stop()
	if _is_frozen:
		_is_frozen = false
		Engine.time_scale = 1.0


## Freeze the game for the given duration (seconds).
## If already frozen, restarts with the longer remaining duration.
func freeze(duration := -1.0) -> void:
	var d := duration if duration > 0.0 else default_duration
	if d <= 0.0:
		return
	_ensure_timer()
	if not _is_frozen:
		_is_frozen = true
		freeze_started.emit()
	Engine.time_scale = 0.0
	if _timer.is_stopped() or d > _timer.time_left:
		_timer.start(d)


func _unfreeze() -> void:
	if not _is_frozen:
		return
	if _timer != null:
		_timer.stop()
	_is_frozen = false
	Engine.time_scale = 1.0
	freeze_ended.emit()


func _ensure_timer() -> void:
	if _timer != null:
		return
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


func _on_timer_timeout() -> void:
	_unfreeze()
