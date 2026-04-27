extends Node
class_name GCSignalBus
## Base class for a per-game centralized signal hub.
##
## The core does NOT autoload an instance and does NOT declare any signals here.
## Each game should subclass this and declare its own typed signals, then
## register the subclass as an autoload (e.g., `SignalBus`).
##
## Usage in a game project:
##
##     # res://autoloads/signal_bus.gd
##     extends GCSignalBus
##     class_name SignalBus
##
##     signal player_died(player: Node)
##     signal score_changed(value: int)
##     signal level_completed(level_id: StringName)
##
## Then register `res://autoloads/signal_bus.gd` as an autoload named `SignalBus`
## and emit / connect from anywhere:
##
##     SignalBus.player_died.emit(self)
##     SignalBus.score_changed.connect(_on_score_changed)
##
## Guidelines:
## - Use the bus only for cross-cutting, unowned events (achievements,
##   global score, "something somewhere died"). Not as a default.
## - For parent/child or sibling-of-known-parent communication, prefer
##   direct signals on the emitter (Signal Up / Call Down).
## - For inter-behavior communication inside one actor, prefer the host's
##   `local_state` blackboard (cheaper, ordered by phase, easy to debug).
## - Keep all bus signals strongly typed. Avoid Variant payloads when possible.
