extends "res://addons/game_core/screens/gc_screen_base.gd"

var enter_count := 0
var exit_count := 0
var last_payload: Dictionary = {}


func enter(payload: Dictionary = {}) -> void:
	enter_count += 1
	last_payload = payload.duplicate(true)


func exit() -> void:
	exit_count += 1