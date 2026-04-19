extends GCService
class_name GCInputService
## Wraps Godot's input system with action-based queries and device detection.

signal device_changed(device_type: StringName)

enum DeviceType { KEYBOARD, GAMEPAD, TOUCH }

var current_device: StringName = &"keyboard"


func start(_context: GCGameContext) -> void:
	super.start(_context)


func is_action_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)


func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)


func is_action_just_released(action: StringName) -> bool:
	return Input.is_action_just_released(action)


func get_action_strength(action: StringName) -> float:
	return Input.get_action_strength(action)


func get_vector(negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName) -> Vector2:
	return Input.get_vector(negative_x, positive_x, negative_y, positive_y)


func detect_device(event: InputEvent) -> void:
	var new_device: StringName
	if event is InputEventKey or event is InputEventMouse:
		new_device = &"keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_device = &"gamepad"
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		new_device = &"touch"
	else:
		return
	if new_device != current_device:
		current_device = new_device
		device_changed.emit(current_device)
