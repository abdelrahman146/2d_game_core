extends "res://addons/game_core/core/gc_service.gd"
class_name DemoLoggingService


func setup(context: GCGameContext) -> void:
	context.set_shared_value(&"demo_boot_count", int(context.get_shared_value(&"demo_boot_count", 0)) + 1)
	print("DemoLoggingService booted. Count:", context.get_shared_value(&"demo_boot_count", 0))


func teardown() -> void:
	print("DemoLoggingService shutting down.")
